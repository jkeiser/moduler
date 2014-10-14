require 'moduler/base/type'
require 'moduler/base/struct_type'
require 'moduler/base/array_type'
require 'moduler/base/hash_type'
require 'moduler/base/set_type'

require 'moduler/base/boolean'
require 'moduler/base/nullable'
require 'moduler/base/value_context'
require 'moduler/lazy_value'
require 'moduler/event'
require 'moduler/validation/coercer'
require 'moduler/validation/coercer_out'
require 'moduler/validation/validator/compound_validator'
require 'moduler/validation/validator/equal_to'
require 'moduler/validation/validator/kind_of'
require 'moduler/validation/validator/regexes'
require 'moduler/validation/validator/cannot_be'
require 'moduler/validation/validator/respond_to'
require 'moduler/validation/validator/validate_proc'

require 'moduler/emitter'

module Moduler
  module TypeDSL
    def self.inline(*args, &block)
      StructType.new.inline(*args, &block)
    end

    module DSL
      def lazy(cache=true, &block)
        Moduler::LazyValue.new(cache, &block)
      end
      def nullable(type=nil)
        type ? Moduler::Base::Nullable[type] : Moduler::Base::Nullable
      end
      def boolean
        Moduler::Base::Boolean
      end

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
    end

    # Round 1: create the types and link them up in a type system
    class Type < Moduler::Base::Type
      include DSL
      def self.for(*args, &block)
        TypeType.new.call(Base::ValueContext.new, *args, &block)
      end
    end
    class StructType < Moduler::Base::StructType
      include DSL
    end
    class HashType < Moduler::Base::HashType
      include DSL
    end
    class ArrayType < Moduler::Base::ArrayType
      include DSL
    end
    class SetType < Moduler::Base::SetType
      include DSL
    end
    class TypeType < StructType
    end

    require 'moduler/type_dsl/type_type'

    class StructType
      def attribute(name, *args, &block)
        context = Base::ValueContext.new(attributes[name]) { |v| attributes[name] = v }
        attributes[name] = Type.for(*args, &block)
      end
    end

    # Round 2: define the attributes!
    class HashType
      attribute :key_type, Type.for(Type)
      attribute :value_type, Type.for(Type)
      attribute :singular, Type.for(Symbol)
    end

    class StructType
      # TODO declare attributes with :no_emit, once we support :no_emit
      #attribute :attributes#, :singular => :attribute
      attribute :specialize_from, Type.for(StructType, :default => {})
      attribute :reopen_on_call, Type.for(Moduler::Base::Boolean, :default => false)
    end
    class ArrayType
      attribute :index_type, Type.for(Type)
      attribute :element_type, Type.for(Type)
      attribute :singular, Type.for(Symbol)
    end
    class Type
      #
      # Coercer that will be run when the user gives us a value to store.
      #
      attribute :coercer, Type.for(Validation::Coercer)
      #
      # A Validator to validate the value.  Will be run on the value before coercion.
      #
      attribute :validator, Type.for(Validation::Validator)
      #
      # Coercer that will be run when the user retrieves a value.
      #
      attribute :coercer_out, Type.for(Validation::CoercerOut)
      #
      # Mostly for "nullable": skip coercion entirely if the value matches the
      # value of this.  If not set, we never skip coercion.
      # Use Moduler::Base::Nullable[Type] for your type to make this happen with
      # +null+.
      #
      attribute :skip_coercion_if
      #
      # Proc to call when a value of this type is a struct field and the user
      # types <struct>.field <args> [do ... end]
      #
      attribute :call_proc, Type.for(Proc)
      #
      # A hash of named events the user has registered listeners for.
      # if !events[:on_set], there are no listeners for on_set.
      #
      attribute :events, Type.for(Hash[Symbol => Event])
      attribute :required, Type.for(Moduler::Base::Boolean)
    end
    class SetType
      attribute :item_type, Type.for(Type)
      attribute :singular, Type.for(Symbol)
    end
    class TypeType
      attribute :specialize_from, Type.for(Type, :default => Type.new)
      attribute :reopen_on_call, Type.for(Moduler::Base::Boolean, :default => true)
    end
  end
end
