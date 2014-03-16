$LOAD_PATH.unshift(File.expand_path("../../..", __FILE__))

Dir.glob("app/services/*.rb").each { |f| require f }

SpecialistPublisher ||= Module.new

SpecialistPublisher.module_eval { |sp|
  sp::ServiceWiring = Class.new { |app|

    SpecialistPublisherWiring.inject_into(app)

    define_method(:list_documents) { |context|
      sp::ListDocuments.new(
        specialist_document_repository,
        context,
      ).call
    }

    define_method(:update_document) { |context|
      sp::UpdateDocument.new(
        specialist_document_repository,
        context,
      ).call
    }

    define_method(:create_document) { |context|
      sp::CreateDocument.new(
        specialist_document_repository,
        specialist_document_builder,
        context,
      ).call
    }
  }

}
