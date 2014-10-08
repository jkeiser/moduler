require 'moduler/type'

module Moduler
  class Type
    #
    # A Validator instance can validate values.
    #
    module Validator
      #
      # Helper to create a validation failure object to return in the failure
      # array.
      #
      # ==== Arguments
      # [value]
      # The value that failed validation.
      # [message]
      # The failure message.
      #
      def validation_failure(value, message)
        { :validator => self, :value => value, :message => message }
      end

      def self.validation_failure(value, message, validator=nil)
        if validator
          { :validator => validator, :value => value, :message => message }
        else
          { :value => value, :message => message }
        end
      end

      #
      # Validate this value.
      #
      # ==== Arguments
      # [value]
      # The value to validate, straight from the user.
      #
      # ==== Returns
      #
      # +false+ if it failed non-specifically
      # +nil+ or +true+ for success
      # A failure message
      # A (possibly empty, indicating success) array of failure messages.
      #
      # Messages are of the form:
      # [
      #   { :validator => <RequiredFields object>, :value => value, :message => "Required fields 'foo' and 'bar' missing" },
      #   { :validator => <KindOf object>, :value => Hash, :message => "Required fields 'foo' and 'bar' missing" }
      # ]
      #
      # Validators will be stacked together and their failure messages taken
      # together.
      #
      def validate(value)
        raise NotImplementedError
      end

      def self.default_validation_failure(validator, value)
        {
          validator: validator,
          value:     value,
          message:   "Validator #{validator} failed on value #{value}"
        }
      end
    end
  end
end
