require 'moduler/dsl/basic'

#
# Simple, extensible and powerful DSL for creating classes and modules.
#
module Moduler
  #
  # Constant indicating a lack of a value (as opposed to +nil+), so that methods
  # know when to fill in defaults.
  #
  NO_VALUE = Object.new

  #
  # Constant indicating a call or event was not handled, so that the caller can
  # take special action.
  #
  NOT_HANDLED = Object.new

  def self.inline(&block)
    Moduler::DSL::Basic.inline(&block)
  end
end
