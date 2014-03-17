require "delegate"
require "active_model/conversion"
require "active_model/naming"

class DocumentPresenter < SimpleDelegator
  extend Forwardable
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def self.name
    "SpecialistDocument"
  end

  def initialize(document, html_preview = nil)
    super(document)
    @html_preview = html_preview
  end

  attr_reader :html_preview

  def persisted?
    updated_at.present?
  end

  def to_param
    id
  end
end
