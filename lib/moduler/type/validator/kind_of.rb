require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      class KindOf
        include Validator

        def initialize(*kinds)
          @kinds = kinds
        end

        attr_accessor :kinds

        def validate(value)
          if kinds.all? { |k| !value.kind_of?(k) }
            validation_failure(value, "Value must be kind_of?(#{kinds.join(", ")}), but is #{value.class}")
          end
        end
      end
    end
  end
end
