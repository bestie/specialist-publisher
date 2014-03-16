SpecialistPublisher.module_eval { |sp|
  sp::CreateDocument = Class.new {
    define_method(:initialize) { |document_repo, document_builder, context|
      @document_repo = document_repo
      @document_builder = document_builder
      @context = context
    }

    define_method(:call) {
      if document_repo.store!(new_document)
        if(context.params.has_key?(:publish))
          document_repo.publish!(new_document)
        end

        context.created(document: new_document)
      else
        context.not_created(document: new_document)
      end
    }

    private

    attr_reader :document_repo, :document_builder, :context

    define_method(:new_document) {
      @new_document ||= document_builder.call(document_params)
    }

    define_method(:document_params) {
      # Note: frontent coupling?
      context.params.fetch(:specialist_document)
    }
  }
}
