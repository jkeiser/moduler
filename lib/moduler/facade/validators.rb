require 'moduler/facade/coercer'
require 'moduler/errors'

module Moduler
  module Facade
    module Validators
      def define_validator(name, &block)
        new_module(name) do |moduler|
          include Coercer
          def coerce(value)
            begin
              value = super(value)
            rescue ValidationFailed => e
              e.failures += Array(instance_exec(value, &block) || [])
              raise
            end
            failures = Array(instance_exec(value, &block) || [])
            if failures.size > 0
              raise ValidationFailed.new(failures)
            end
          end
        end.target
      end

      def validation_failure(type, facade, message)
        { :type => type, :facade => facade, :message => message }
      end

      #
      #
      #
      def required_fields(field_names)
        define_validator(module_name(:required_fields, *field_names)) do |value|
          return field_names.
              select { |name| !value.has_key?(name) }.
              map    { |name| validation_failure(:required_fields, self, "Missing required field #{name}.") }
        end
      end

      #
      # Run all the callbacks, throwing an error if any return a false value or
      # [ false, "error message", ... ].
      #
      def validate(validators)
        define_validator(module_name(:validate, *validators)) do |value|
          failures = []
          validators.each do |validator|
            succeeded, *errors = validator.call(value)
            if !succeeded
              failures += errors.size ? errors : [ "Validate callback failed" ]
            end
          end
          failures
        end
      end

      #
      # Validates false if the value is not one of the given kinds
      #
      def kind_of(kinds)
        define_validator(module_name(:kind_of, *kinds)) do |value|
          if !kinds.any? { |k| !value.kind_of?(k) }
            [ "Value must be kind_of?(#{kinds.join(", ")}), but is #{value.class}" ]
          end
        end
      end

      def equal_to(values)
        define_validator(module_name(:equal_to, *values)) do |value|
          if !values.include?(value)
            [ "Value must be equal to one of (#{kind_of.map { |k| k.inspect }.join(", ")}), but is #{value.inspect}" ]
          end
        end
      end

      def regexes(regexes)
        define_validator(module_name(:regexes, *regexes)) do |value|
          if !regexes.any? { |regex| regex.match(value) }
            [ "Value must match one of (#{regexes.map { |r| r.inspect }.join(", ")}), but does not: #{value.inspect}" ]
          end
        end
      end
    end
  end
end
