class SpecialistDocumentsController < ApplicationController

  def index
    render_with(documents: all_documents)
  end

  def new
    render_with(document: presentable_document(new_document({})))
  end

  def edit
    render_with(document: presentable_document(current_document))
  end

  def create
    document = new_document(form_params)

    if preview_requested?
      display_preview(document, :new)
    else
      store_and_redirect(document, :new)
    end
  end

  def update
    current_document.update(form_params)

    if preview_requested?
      display_preview(current_document, :edit)
    else
      store_and_redirect(current_document, :edit)
    end
  end

  def preview
    render json: { preview_html: generate_preview }
  end

protected

  def preview_requested?
    params.has_key?(:preview)
  end

  def display_preview(document, action_to_render)
    html_preview = generate_preview(document)

    render(action_to_render, locals: {
      document: presentable_document(document, html_preview)
    })
  end

  def all_documents
    specialist_document_repository.all.lazy.map { |d|
      presentable_document(d)
    }
  end

  def new_document(doc_params)
    specialist_document_builder.call(doc_params)
  end

  def current_document
    @current_document ||= specialist_document_repository.fetch(params.fetch(:id))
  end

  def generate_preview(document = preview_document)
    specialist_document_renderer.call(document).body
  end

  def preview_document
    if current_document
      current_document.update(form_params)
    else
      build_from_params
    end
  end

  def store_and_redirect(document, error_action_name)
    if store(document, publish: params.has_key?('publish'))
      redirect_to specialist_documents_path
    else
      render(error_action_name, locals: {document: presentable_document(document)})
    end
  end

  def store(document, publish: false)
    stored_ok = specialist_document_repository.store!(document)
    if stored_ok && publish
      specialist_document_repository.publish!(document)
    end
    stored_ok
  end

  def presentable_document(doc, preview = nil)
    document_presenter_factory.call(doc, preview)
  end

  def form_params
    params.fetch(:specialist_document, {})
  end

  def build_from_params
    specialist_document_builder.call(form_params)
  end
end
