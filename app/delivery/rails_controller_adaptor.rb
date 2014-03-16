require "app/specialist_publisher"
require "forwardable"

SpecialistPublisher.module_eval { |sp|
  sp::RailsControllerAdapter = Class.new {
    extend Forwardable

    def_delegators(:controller,
      :params,
    )

    define_method(:initialize) { |controller|
      @controller = controller
    }

    define_method(:success) { |vars|
      render_with(vars)
    }

    define_method(:created) { |vars|
      redirect_to_index
    }

    define_method(:updated) { |vars|
      redirect_to_index
    }

    define_method(:not_created) { |vars|
      render_new(vars)
    }

    define_method(:not_updated) { |vars|
      render_edit(vars)
    }

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
