require "app/specialist_publisher"

SpecialistPublisher.module_eval { |root|
  root::ListDocuments = Class.new {
    def initialize(documents, context)
      @documents = documents
      @context = context
    end

    def call
      context.success(documents: documents.all)
    end

    private

    attr_reader :documents, :context
  }
}
