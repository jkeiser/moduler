require 'moduler/errors'

module Moduler
  module Type
    def coerce(value)
      if value.is_a?(LazyValue)
        # Leave lazy values alone until we retrieve them
        value
      else
        value = super(value)
        validate(value)
        value
      end
    end

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

      if cannot_be
        cannot_be.each do |thing|
          if value.respond_to?(:"#{thing}?") && value.send(:"#{thing}?")
            errors << "Value #{value.inspect} is #{thing}."
          end
        end
      end
      if equal_to && equal_to.size > 0
        if !equal_to.include?(value)
          errors << "Value must be equal to one of (#{equal_to.map { |k| k.inspect }.join(", ")}), but is #{value.inspect}"
        end
      end
      if kind_of && kind_of.size > 0
        if kind_of.all? { |k| !value.kind_of?(k) }
          errors << "Value must be kind_of?(#{kind_of.join(", ")}), but is #{value.class}"
        end
      end
      if regexes && regexes.size > 0
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
      if respond_to
        respond_to.each do |name|
          if !value.respond_to?(name)
            errors << "Value #{value.inspect} (#{value.class}) does not respond to #{name}"
          end
        end
      end
      if validators
        validators.each do |validator|
          result = validator.call(value)
          if result == false
            errors << "Validator proc failed on value #{value}"
          elsif !result.nil? && !(result == true)
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
