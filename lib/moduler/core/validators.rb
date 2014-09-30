require 'moduler/errors'

module Moduler
  module Core
    module Validators
      def define_validator(moduler, name, &block)
        moduler.define_module(name) do
          include Transform

          def self.coerce(value)
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
        end
      end

      def self.validation_failure(type, facade, message)
        { :type => type, :facade => facade, :message => message }
      end

      #
      #
      #
      def required_fields(field_names)
        define_validator(moduler, module_name("required_fields", field_names)) do |value|
          return field_names.
              select { |name| !value.has_key?(name) }.
              map    { |name| validation_failure(:required_fields, self, "Missing required field #{name}.") }
          end
        end
      end

      #
      # Run all the callbacks, throwing an error if any return a false value or
      # [ false, "error message", ... ].
      #
      def validate(validators)
        define_validator(moduler, module_name("required_fields", field_names)) do |value|
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
        define_validator(moduler, module_name("required_fields", field_names)) do |value|
          if !kinds.any? { |k| !value.kind_of?(k) }
            [ "Value must be kind_of?(#{kinds.join(", ")}), but is #{value.class}" ]
          end
        end
      end

      def equal_to(values)
        define_validator(moduler, module_name("required_fields", field_names)) do |value|
          if !values.include?(value)
            [ "Value must be equal to one of (#{values.map { |v| v.inspect }.join(", ")}), but is #{value.inspect}" ]
          end
        end
      end

      def regexes(regexes)
        define_validator(moduler, module_name("required_fields", field_names)) do |value|
          if !kinds.any? { |k| !value.kind_of?(k) }
            [ "Value must match one of (#{regexes.map { |v| v.inspect }.join(", ")}), but does not: #{value.inspect}" ]
          end
        end
      end
    end
  end
end
