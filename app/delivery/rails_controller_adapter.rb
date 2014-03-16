require "forwardable"

SpecialistPublisher.module_eval { |sp|
  sp::RailsControllerAdapter = Class.new {
    extend Forwardable

    define_method(:initialize) { |controller|
      @controller = controller
    }

    response_strategies = {
      # These would be configurable to facilitate traditional Rails controller
      # redirection flows or a simple JSON API where the data is just returned
      # with different status codes.
      :created        => ->(c, o){ c.redirect_to(:index) },
      :not_created    => ->(c, v){ c.render_action_with(:new, v) },
      :updated        => ->(c, o){ c.redirect_to(:index) },
      :not_updated    => ->(c, v){ c.render_action_with(:edit, v) },
      :deleted        => ->(c, o){ redirect_to(:index) },
    }

    response_strategies.keys.each { |response_type|
      define_method(response_type) { |data|
        response_strategies.fetch(response_type).call(self, data)
      }
    }

    define_method(:success) { |vars|
      render_with(vars)
    }

    def_delegators(:controller,
      :params,
    )

    private

    attr_reader(
      :controller,
    )

    def_delegators(:controller,
      :controller_name,
      :action_name,
    )

    define_method(:render_new) { |vars|
      render_action_with(:new, vars)
    }

    define_method(:render_edit) { |vars|
      render_action_with(:edit, vars)
    }

    define_method(:redirect_to_index) {
      controller.redirect_to(controller_default_index_path)
    }

    define_method(:redirect_to) { |action|
      controller.redirect_to(action: action)
    }

    define_method(:controller_default_index_path) {
      controller.public_send(controller.controller_path + "_path")
    }

    define_method(:render_with) { |locals|
      render_action_with(action_name, locals)
    }

    define_method(:render_action_with) { |action_to_render, locals = {}|
      controller.render(template_path(action_to_render), locals: locals)
    }

    define_method(:template_path) { |action_to_render|
      [ controller_name, action_to_render ].join("/")
    }
  }
}
