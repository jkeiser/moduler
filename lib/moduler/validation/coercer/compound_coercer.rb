require 'moduler/validation/coercer'

module Moduler
  module Validation
    module Coercer
      class CompoundCoercer
        include Coercer

        def initialize(*coercers)
          @coercers = coercers
        end

        attr_accessor :coercers

        def coerce(value)
          coercers.inject(value) { |value,coercer| coercer.coerce(value) }
        end
      end
    end
  end
end
