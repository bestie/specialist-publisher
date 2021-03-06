require 'specialist_publisher_wiring'

class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  before_filter :require_signin_permission!

  protect_from_forgery with: :exception

  SpecialistPublisherWiring.inject_into(self)
end
