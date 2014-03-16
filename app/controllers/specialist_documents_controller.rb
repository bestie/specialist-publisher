require "service_wiring"
require "rails_controller_adapter"

class SpecialistDocumentsController < ApplicationController

  def index
    app.list_documents(adapter)
  end

  def new
    render_with(document: new_document({}))
  end

  def edit
    render_with(document: current_document)
  end

  def create
    app.create_document(adapter)
  end

  def update
    app.update_document(adapter)
  end

  def preview
    render json: { preview_html: generate_preview }
  end

protected

  def all_documents
    specialist_document_repository.all
  end

  def new_document(doc_params)
    specialist_document_builder.call(doc_params)
  end

  def current_document
    specialist_document_repository.fetch(params.fetch(:id))
  end

  def generate_preview
    if current_document
      preview_document = current_document.update(form_params)
    else
      preview_document = build_from_params
    end

    specialist_document_renderer.call(preview_document).body
  end

  def store_and_redirect(document, error_action_name)
    if store(document, publish: params.has_key?('publish'))
      redirect_to specialist_documents_path
    else
      render_action_with(error_action_name, document: document)
    end
  end

  def store(document, publish: false)
    stored_ok = specialist_document_repository.store!(document)
    if stored_ok && publish
      specialist_document_repository.publish!(document)
    end
    stored_ok
  end

  def form_params
    params.fetch(:specialist_document, {})
  end

  def build_from_params
    specialist_document_builder.call(form_params)
  end

  def app
    @app ||= SpecialistPublisher::ServiceWiring.new
  end

  def adapter
    SpecialistPublisher::RailsControllerAdapter.new(self)
  end
end
