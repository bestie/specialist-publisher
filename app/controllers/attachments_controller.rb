class AttachmentsController < ApplicationController
  def new
    render_with(
      document: presentable_document(document),
      new_attachment: new_attachment,
    )
  end

  def create
    document.add_attachment(form_params)
    specialist_document_repository.store!(document)

    redirect_to edit_specialist_document_path(presentable_document(document))
  end

private

  def presentable_document(document)
    document_presenter_factory.call(document)
  end

  def document
    @document ||= specialist_document_repository.fetch(document_id)
  end

  def new_attachment
    attachment_factory.call({})
  end

  def form_params
    params.fetch(:attachment)
  end

  def document_id
    params.fetch(:specialist_document_id)
  end
end
