require 'moduler'
require 'moduler/lazy_value'
require 'moduler/event'
require 'moduler/base/type'
require 'moduler/validation/validator/compound_validator'
require 'moduler/validation/validator/equal_to'
require 'moduler/validation/validator/kind_of'
require 'moduler/validation/validator/regexes'
require 'moduler/validation/validator/cannot_be'
require 'moduler/validation/validator/respond_to'
require 'moduler/validation/validator/validate_proc'

module Moduler
  #
  # Types are Moduler's way of describing how values can be get, set and
  # traversed.
  #
  # Different Type systems will have different (sometimes radically different)
  # capabilities, but the one thing they have in common is that they take in
  # values and spit out values.
  #
  # Subclasses:
  # - ArrayType:
  # - HashType:
  # - StructType:
  # - SetType:
  # - TypeType: requires a Type.
  #
  class Type < Base::Type
    def self.type_type
      Moduler::Type::TypeType.empty
    end
    require 'moduler/type/type_type'

    #
    # Pure DSL methods
    #
    def lazy(cache=true, &block)
      Moduler::LazyValue.new(cache, &block)
    end

    # TODO move the pure DSL into a module or something so it can be mixed
    def equal_to(*values)
      add_validator(Moduler::Validation::Validator::EqualTo.new(*values))
    end
    def kind_of(*kinds)
      add_validator(Moduler::Validation::Validator::KindOf.new(*kinds))
    end
    def regex(*regexes)
      add_validator(Moduler::Validation::Validator::Regexes.new(*regexes))
    end
    def cannot_be(*truthy_things)
      add_validator(Moduler::Validation::Validator::CannotBe.new(*truthy_things))
    end
    def respond_to(*method_names)
      add_validator(Moduler::Validation::Validator::RespondTo.new(*method_names))
    end
    def callbacks(callbacks)
      add_validator(ModulerValidation::Validator::ValidateProc.new do |value|
        callbacks.select do |message, callback|
          callback.call(value) != true
        end.map do |message, callback|
          validation_failure("Value #{value} #{message}!")
        end
      end)
    end

    attribute :required#, :equal_to => [true, false], :default => false
  end
end

require 'moduler/type/hash_type'
require 'moduler/type/array_type'
require 'moduler/type/set_type'
require 'moduler/type/struct_type'
