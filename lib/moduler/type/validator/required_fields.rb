require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      class RequiredFields
        include Validator

        def initialize(field_names)
          @field_names = field_names
        end

        attr_accessor :field_names

        def validate(value)
          return field_names.
              select { |name| !value.has_key?(name) }.
              map    { |name| validation_failure(:required_fields, self, "Missing required field #{name}.") }
        end
      end
    end
  end
end
