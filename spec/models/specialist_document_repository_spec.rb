require 'spec_helper'

describe SpecialistDocumentRepository do

  let(:panopticon_api) do
    double(:panopticon_api)
  end

  let(:panopticon_mappings) { PanopticonMapping }

  let(:publication_observers) { [publication_observer] }
  let(:publication_observer)  { double(:publication_observer, call: nil) }

  let(:specialist_document_repository) do
    SpecialistDocumentRepository.new(
      panopticon_mappings,
      SpecialistDocumentEdition,
      panopticon_api,
      document_factory,
      publication_observers,
    )
  end

  let(:document_factory) { double(:document_factory, call: document) }

  let(:document_id) { "document-id" }

  let(:document) {
    SpecialistDocument.new(slug_generator, edition_factory, document_id, editions)
  }

  let(:slug_generator) { double(:slug_generator) }

  let(:edition_factory) { double(:edition_factory) }
  let(:editions) { [new_draft_edition] }

  let(:new_draft_edition) {
    double(
      :new_draft_edition,
      :title => "Example document about oil reserves",
      :slug => "example-document-about-oil-reserves",
      :"document_id=" => nil,
      :"slug=" => nil,
      :changed? => true,
      :save => true,
      :published? => false,
      :draft? => true,
      :errors => {},
      :publish => nil,
      :version_number => 2,
    )
  }

  def build_published_edition(version: 1)
    double(
      :published_edition,
      :title => "Example document about oil reserves #{version}",
      :"document_id=" => nil,
      :changed? => false,
      :save => nil,
      :archive => nil,
      :published? => true,
      :draft? => false,
      :version_number => version,
    )
  end

  def build_specialist_document(*args)
    SpecialistDocument.new(slug_generator, edition_factory, *args)
  end

  let(:published_edition) { build_published_edition }

  describe "#all" do
    before do
      @edition_1, @edition_2 = [2, 1].map do |n|
        edition = FactoryGirl.create(:specialist_document_edition,
                            document_id: "document-id-#{n}",
                            updated_at: n.days.ago)

        allow(document_factory).to receive(:call)
          .with("document-id-#{n}", [edition])
          .and_return(build_specialist_document("document-id-#{n}", [edition]))

        edition
      end
    end

    it "returns all documents by date updated desc" do
      specialist_document_repository.all.map(&:title).should == [@edition_2, @edition_1].map(&:title)
    end
  end

  describe "#fetch" do
    let(:editions_proxy) { double(:editions_proxy, to_a: editions) }
    let(:editions)       { [ published_edition ] }

    before do
      allow(SpecialistDocument).to receive(:new).and_return(document)
      allow(SpecialistDocumentEdition).to receive(:where)
        .with(document_id: document_id)
        .and_return(editions_proxy)
    end

    it "populates the document with all editions for that document id" do
      specialist_document_repository.fetch(document_id)

      expect(document_factory).to have_received(:call).with(document_id, editions)
    end

    it "returns the document" do
      expect(specialist_document_repository.fetch(document_id)).to eq(document)
    end

    context "when there are no editions" do
      before do
       allow(SpecialistDocumentEdition).to receive(:where)
        .with(document_id: document_id)
        .and_return([])
      end

      it "returns nil" do
        expect(specialist_document_repository.fetch(document_id)).to be(nil)
      end
    end
  end

  context "when the document is new" do
    before do
      @document = build_specialist_document(document_id, [new_draft_edition])
      @panopticon_id = 'some-panopticon-id'
      @panopticon_response = {
        'id' => @panopticon_id,
        'slug' => @document.slug,
      }
      allow(panopticon_api).to receive(:create_artefact!).and_return(@panopticon_response)
    end

    describe "#store!(document)" do
      it "creates a draft artefact" do
        panopticon_api.should_receive(:create_artefact!).with(
          hash_including(
            slug: @document.slug,
            name: @document.title,
            state: 'draft',
            owning_app: 'specialist-publisher',
            rendering_app: 'specialist-frontend',
            paths: ["/#{@document.slug}"],
          )
        )

        specialist_document_repository.store!(@document)
      end

      it "stores a mapping of document id to panopticon id and slug" do
        specialist_document_repository.store!(@document)

        mapping = PanopticonMapping.where(document_id: @document.id).last
        expect(mapping.panopticon_id).to eq(@panopticon_id)
        expect(mapping.slug).to eq(@document.slug)
      end
    end
  end

  describe "#store!(document)" do
    context "with an invalid document" do
      before do
        allow(new_draft_edition).to receive(:save).and_return(false)
      end

      it "returns false" do
        expect(specialist_document_repository.store!(document)).to be false
      end
    end

    context "with a valid document" do
      before do
        allow(panopticon_api).to receive(:create_artefact!).and_return({'id' => panopticon_id})
      end

      let(:panopticon_id) { 'some-panopticon-id' }

      let(:latest_edition) { new_draft_edition }
      let(:previous_edition) { published_edition }

      let(:editions) { [previous_edition, latest_edition] }

      it "returns true" do
        expect(specialist_document_repository.store!(document)).to be true
      end

      it "assigns the document_id edition" do
        specialist_document_repository.store!(document)

        expect(latest_edition).to have_received(:document_id=).with(document_id)
      end

      it "only saves the latest edition" do
        specialist_document_repository.store!(document)

        expect(latest_edition).to have_received(:save)
        expect(previous_edition).not_to have_received(:save)
      end
    end
  end

  context "when panopticon raises an exception, eg duplicate slug" do
    before do
      exception = GdsApi::HTTPErrorResponse.new(422, 'errors' => {slug: ['already taken']})
      allow(panopticon_api).to receive(:create_artefact!).and_raise(exception)
    end

    describe "#store!" do
      let(:editions) { [new_draft_edition] }

      it "sets error messages on the document" do
        specialist_document_repository.store!(document)
        expect(new_draft_edition.errors[:slug]).to include('already taken')
      end

      it "returns false" do
        specialist_document_repository.store!(document).should == false
      end
    end
  end

  describe "#publish" do
    let(:document_title)        { double(:document_title) }
    let(:document_slug)         { double(:document_slug) }
    let(:document_id)           { double(:document_id) }
    let(:panopticon_id)         { double(:panopticon_id) }

    let(:panopticon_mapping) {
      double(:panopticon_mapping, panopticon_id: panopticon_id)
    }

    let(:doc) {
      double(:doc,
        id: document_id,
        published?: false,
        previous_editions: [],
        latest_edition: new_draft_edition,
        title: document_title,
        slug: document_slug,
      )
    }

    before do
      allow(panopticon_mappings).to receive(:where)
        .with(document_id: document_id)
        .and_return([panopticon_mapping])

      allow(panopticon_api).to receive(:put_artefact!)
    end

    it "notifies the observers" do
      specialist_document_repository.publish!(doc)

      expect(publication_observer).to have_received(:call).with(doc)
    end

    context "when has no mapping" do
      before do
        allow(panopticon_mappings).to receive(:where)
          .with(document_id: document_id)
          .and_return([])
      end

      it "raises an InvalidDocumentError" do
        expect { specialist_document_repository.publish!(doc) }
          .to raise_error(SpecialistDocumentRepository::InvalidDocumentError)
      end
    end

    context "when the document exists and is published" do
      let(:doc) {
        double(:doc,
          id: document_id,
          published?: true,
          previous_editions: [published_edition],
          latest_edition: latest_published_edition,
        )
      }

      let(:latest_published_edition) { build_published_edition(version: 2) }

      describe "#publish!(document)" do
        it "archives old editions" do
          specialist_document_repository.publish!(doc)

          expect(published_edition).to have_received(:archive)
          expect(latest_published_edition).not_to have_received(:archive)
        end

        it "does not notify panopticon of the update" do
          specialist_document_repository.publish!(doc)

          expect(panopticon_api).not_to receive(:put_artefact!)
        end
      end
    end

    context "when the document exists in draft" do
      let(:doc) {
        double(:doc,
          id: document_id,
          published?: false,
          previous_editions: [],
          latest_edition: new_draft_edition,
          title: document_title,
          slug: document_slug,
        )
      }

      describe "#publish!(document)" do
        it "the document becomes published" do
          specialist_document_repository.publish!(doc)

          expect(new_draft_edition).to have_received(:publish)
        end

        it "notifies panopticon of the update" do
          specialist_document_repository.publish!(doc)

          expect(panopticon_api).to have_received(:put_artefact!)
            .with(panopticon_mapping.panopticon_id, hash_including(
              name: document_title,
              slug: document_slug,
            ))
        end
      end
    end
  end

end
