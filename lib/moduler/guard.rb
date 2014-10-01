require 'moduler'
require 'moduler/guard/coercer'

module Moduler
  module Guard
    def get
      coerce_out(raw)
    end
    def set(value)
      raw = coerce(value)
    end
    def call(value = NOT_PASSED, &block)
      if value == NOT_PASSED
        if block
          set(block)
        else
          get
        end
      elsif block
        raise "Both value and block passed to attribute!  Only one at a time accepted."
      else
        set(value)
      end
    end
  end
end
