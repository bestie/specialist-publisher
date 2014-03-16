SpecialistPublisher.module_eval { |sp|
  sp::UpdateDocument = Class.new {
    define_method(:initialize) { |document_repo, context|
      @document_repo = document_repo
      @context = context
    }

    define_method(:call) {
      document.update(document_params)

      if document_repo.store!(document)
        if(context.params.has_key?(:publish))
          document_repo.publish!(document)
        end

        context.updated(document: document)
      else
        context.not_updated(document: document)
      end
    }

    private

    attr_reader :document_repo, :context

    define_method(:document) {
      @document ||= document_repo.fetch(document_id)
    }

    define_method(:document_id) {
      context.params.fetch(:id)
    }

    define_method(:document_params) {
      # Note: frontent coupling?
      context.params.fetch(:specialist_document)
    }
  }
}
