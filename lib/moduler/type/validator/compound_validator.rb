require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      #
      # Runs through a number of validators, appending their results.
      #
      class CompoundValidator
        include Validator

        def initialize(*validators)
          @validators = validators
        end

        attr_accessor :validators

        def validate(value)
          result = []
          validators.each do |validator|
            local_result = validator.validate(value)
            if local_result.is_a?(Array)
              result += local_result
            elsif local_result == false
              result << Validator.default_validation_failure(validator, value)
            end
          end
          result
        end
      end
    end
  end
end
