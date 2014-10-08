require 'moduler/type/coercer_out'

module Moduler
  class Type
    module CoercerOut
      class CompoundCoercerOut
        include CoercerOut

        def initialize(*coercers_out)
          @coercers_out = coercers_out
        end

        attr_accessor :coercers_out

        def coerce_out(value)
          coercers_out.inject(value) { |value,coercer_out| coercer_out.coerce_out(value) }
        end
      end
    end
  end
end
