require 'moduler/validation/validator'

module Moduler
  module Validation
    module Validator
      class RequiredFields
        include Validator

        def initialize(*field_names)
          @field_names = field_names
        end

        attr_accessor :field_names

        def validate(value)
          if value.respond_to?(:has_key?)
            field_names.
                select { |name| !value.has_key?(name) }.
                map    { |name| validation_failure(self, "Missing required field #{name}.") }
          else
            validation_failure(self, "Value must have fields #{field_names.join(', ')}, but is not a hash: #{value.inspect}")
          end
        end
      end
    end
  end
end
