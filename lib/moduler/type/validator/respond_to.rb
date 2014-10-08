require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      class RespondTo
        include Validator

        def initialize(*method_names)
          @method_names = method_names
        end

        attr_accessor :method_names

        def validate(value)
          method_names.select { |name| !value.respond_to?(name) }.map do |name|
            validation_failure(value, "Value #{value.inspect} (#{value.class}) does not respond to #{name}")
          end
        end
      end
    end
  end
end
