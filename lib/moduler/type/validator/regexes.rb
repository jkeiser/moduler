require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      class Regexes
        include Validator

        def initialize(*regexes)
          @regexes = regexes
        end

        attr_accessor :regexes

        def validate(value)
          if value.respond_to?(:match)
            if regexes.all? { |regex| !value.match(regex) }
              validation_failure(value, "Value must match one of (#{regexes.map { |r| r.inspect }.join(", ")}), but does not: #{value.inspect}")
            end
          else
            validation_failure(value, "Value must match one of (#{regexes.map { |r| r.inspect }.join(", ")}), but is not a string: #{value.inspect}")
          end
        end
      end
    end
  end
end
