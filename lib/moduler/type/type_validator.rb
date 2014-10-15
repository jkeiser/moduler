require 'moduler/errors'

module Moduler
  module Type
    #
    # Run the validator against the value, throwing a ValidationError if there
    # are issues.
    #
    # Generally, you should be running coerce(), as it is possible for coerce
    # methods to do some validation.
    #
    def validate(value)
      if nullable && value.nil?
        return
      end

      errors = []

      if cannot_be.size > 0
        errors += cannot_be.
          select { |thing| value.respond_to?(:"#{thing}?") && value.send(:"#{thing}?") }.
          map { |thing| "Value #{value.inspect} is #{thing}." }
      end
      if equal_to.size > 0
        if !equal_to.include?(value)
          errors << "Value must be equal to one of (#{equal_to.map { |k| k.inspect }.join(", ")}), but is #{value.inspect}"
        end
      end
      if kind_of.size > 0
        if kind_of.all? { |k| !value.kind_of?(k) }
          errors << "Value must be kind_of?(#{kind_of.join(", ")}), but is #{value.class}"
        end
      end
      if regexes.size > 0
        if value.respond_to?(:match)
          if regexes.all? { |regex| !value.match(regex) }
            errors << "Value must match one of (#{regexes.map { |r| r.inspect }.join(", ")}), but does not: #{value.inspect}"
          end
        else
          errors << "Value must match one of (#{regexes.map { |r| r.inspect }.join(", ")}), but is not a string: #{value.inspect}"
        end
      end
      # required fields
      # if value.respond_to?(:has_key?)
      #   errors += field_names.
      #       select { |name| !value.has_key?(name) }.
      #       map    { |name| "Missing required field #{name}." }
      # else
      #   errors << "Value must have fields #{field_names.join(', ')}, but is not a hash: #{value.inspect}"
      # end
      if respond_to.size > 0
        respond_to.select { |name| !value.respond_to?(name) }.map do |name|
          errors << "Value #{value.inspect} (#{value.class}) does not respond to #{name}"
        end
      end
      if validators.size > 0
        validators.each do |validator|
          result = validator.call(value)
          if result == false
            errors << "Validator proc failed on value #{value}"
          else
            errors += Array(result)
          end
        end
      end

      if errors.size > 0
        raise ValidationFailed.new(errors)
      end
    end
  end
end
