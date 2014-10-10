require 'moduler/validation/validator'

module Moduler
  module Validation
    module Validator
      class CannotBe
        include Validator

        def initialize(*truthy_things)
          @truthy_things = truthy_things
        end

        attr_accessor :truthy_things

        def validate(value)
          truthy_things.
            select { |thing| value.respond_to?(:"#{thing}?") && value.send(:"#{thing}?") }.
            map do |thing|
              validation_failure(value, "Value #{value.inspect} is #{thing}.")
            end
        end
      end
    end
  end
end
