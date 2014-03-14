require 'specialist_publisher_wiring'

class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  before_filter :require_signin_permission!

  protect_from_forgery with: :exception

  SpecialistPublisherWiring.inject_into(self)

  def render_with(locals)
    render_action_with(action_name, locals)
  end

  def render_action_with(action_name, locals = {})
    render([controller_name, action_name].join("/"), locals: locals)
  end
end
