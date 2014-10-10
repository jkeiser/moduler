require 'moduler/validation/validator'

module Moduler
  module Validation
    module Validator
      class ValidateProc
        include Validator

        def initialize(validate_proc=nil, &block)
          @validate_proc = block || validate_proc
        end

        attr_accessor :validate_proc

        def validate(value)
          validate_proc.call(value)
        end
      end
    end
  end
end