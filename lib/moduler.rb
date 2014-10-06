#
# Simple, extensible and powerful DSL for creating classes and modules.
#
module Moduler
  #
  # Run the Moduler DSL against the current module or class.
  #
  # The module/class is detected based on the block's self (the place the
  # block was created).
  #
  # def self.inline(options={}, &block)
  #   Moduler::DSL::DSL.inline(options, &block)
  # end

  #
  # Run the Moduler DSL against a separate module or class.
  #
  # def self.dsl_eval(target, options={}, &block)
  #   Moduler::DSL::DSL.new(options.merge(target: target), &block)
  # end

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

  #
  # Constant used for methods that want to find out whether they passed a value
  # or not.  This should *never* be passed to another method (while the other
  # two constant may).
  #
  NOT_PASSED = Object.new
end
