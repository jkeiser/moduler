require 'moduler/type/validator'

module Moduler
  class Type
    module Validator
      class ValidateProc
        include Validator

        def initialize(validate_proc)
          @validate_proc = validate_proc
        end

        attr_accessor :validate_proc

        def validate(value)
          validate_proc.call(value)
        end
      end
    end
  end
end
