require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      class EqualTo
        include Validator

        def initialize(values)
          @values = values
        end

        attr_accessor :values

        def validate(value)
          if !values.include?(value)
            validation_failure(value, "Value must be equal to one of (#{values.map { |k| k.inspect }.join(", ")}), but is #{value.inspect}")
          end
        end
      end
    end
  end
end
