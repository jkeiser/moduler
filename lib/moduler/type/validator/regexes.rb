require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      class Regexes
        include Validator

        def initialize(regexes)
          @regexes = regexes
        end

        attr_accessor :regexes

        def validate(value)
          if !regexes.any? { |regex| regex.match(value) }
            validation_failure("Value must match one of (#{regexes.map { |r| r.inspect }.join(", ")}), but does not: #{value.inspect}")
          end
        end
      end
    end
  end
end
