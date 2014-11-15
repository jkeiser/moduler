require 'moduler/value/typed'

module Moduler
  #
  # A Facade gives the user an alternate interface to a raw value (or values).
  #
  module Facade
    include Value::Typed

    def initialize(raw, type, context)
      super(raw, type)
      @context = context
    end

    attr_reader :context

    def raw(context=NOT_PASSED)
      super(context == NOT_PASSED ? self.context : context)
    end

    def raw_read(context=NOT_PASSED)
      super(context == NOT_PASSED ? self.context : context)
    end

    def get(context=NOT_PASSED)
      super(context == NOT_PASSED ? self.context : context)
    end

    def child_value(value)
      # If we are not writeable, our children are essentially default values.
      # When someone writes to the child we return, we need to turn ourselves
      # writeable, as well.
      if !writeable?
        if value.is_a?(Value)
          context = self.context
          return Value::Default.new(value) { ensure_writeable(context) }
        elsif !value.nil? && !value.frozen?
          ensure_writeable(context)
        end
      end
      value
    end
  end
end
