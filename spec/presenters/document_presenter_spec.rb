require "support/fast_spec_helper"

require "document_presenter"

describe DocumentPresenter do
  subject(:presenter) { DocumentPresenter.new(doc, preview) }

  let(:doc)     { double(:doc) }
  let(:preview) { double(:preview) }

  it "appears as a SpecialistDocument to ActiveModel forms" do
    expect(DocumentPresenter.model_name).to eq("SpecialistDocument")
  end

  describe "#to_param" do
    let(:doc_id) { double(:doc_id) }

    before do
      allow(doc).to receive(:id).and_return(doc_id)
    end

    it "parameterizes to its ID" do
      expect(presenter.to_param).to eq(doc_id)
    end
  end

  describe "#persisted?" do
    context "when document updated at has not been set" do
      let(:doc) { double(:doc, updated_at: nil) }

      it "is not persisted" do
        expect(presenter).not_to be_persisted
      end
    end

    context "when document updated at has been set" do
      let(:doc) { double(:doc, updated_at: "any value") }

      it "is persisted" do
        expect(presenter).to be_persisted
      end
    end
  end

  describe "#html_preview" do
    it "exposes the preview" do
      expect(presenter.html_preview).to eq(preview)
    end
  end
end
