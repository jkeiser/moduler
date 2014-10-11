require 'moduler/base/type_system'
require 'moduler/base/boolean'
require 'moduler/base/nullable'
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

module Moduler
  module TypeDSL
    def self.type_system
      @type_system ||= Base::TypeSystem.new(self)
    end

    # Round 1: create the types and link them up in a type system
    class Type
      include Moduler::Base::Mix::Type
      def self.type_system
        TypeDSL.type_system
      end
      def type_system
        self.class.type_system
      end
    end
    class StructType < Type
      include Moduler::Base::Mix::StructType
    end
    class TypeType < StructType
      include Moduler::Base::Mix::TypeType
    end
    class HashType < Type
      include Moduler::Base::Mix::HashType
    end
    class ArrayType < Type
      include Moduler::Base::Mix::ArrayType
    end
    class SetType < Type
      include Moduler::Base::Mix::SetType
    end

    # Round 2: add support for "attribute"
    class Type
      def self.type
        @type ||= type_system.type_type.specialize(facade_class: self)
      end

      # Mock out attributes we intend to override
      def coercer_out; end
      def coercer; end
      def validator; end
      def events; end
      def call_proc; end
      def skip_coercion_if; end

      # Actual DSL
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
    class StructType
      def attributes
        @hash[:attributes] ||= {}
      end
    end

    # Round 2: define the attributes!
    class HashType
      type.inline do
        attribute :key_type, Type
        attribute :value_type, Type
        attribute :singular, Symbol
      end
    end
    class StructType
      attribute_type = type_system.type(Hash[Symbol => Type])
      type.inline do
        attribute :attributes, attribute_type
        attribute :specialize_from, Type
        attribute :reopen_on_call, boolean, :default => false
      end
      singular_attribute_proc = Base::Attribute.singular_hash_proc(:attributes, attribute_type)
      define_method(:_singular_attribute, singular_attribute_proc)

      def attribute(*args, &block)
        # If the user doesn't pass a type, set the type to nil rather than getting the type
        if args.size == 1 && !block && args[0].is_a?(Symbol)
          _singular_attribute(args[0], nil)
        else
          _singular_attribute(*args, &block)
        end
      end
    end
    class ArrayType
      type.inline do
        attribute :index_type, Type
        attribute :element_type, Type
        attribute :singular, Symbol
      end
    end
    class Type
      type.inline do
        #
        # Coercer that will be run when the user gives us a value to store.
        #
        attribute :coercer, Validation::Coercer
        #
        # A Validator to validate the value.  Will be run on the value before coercion.
        #
        attribute :validator, Validation::Validator
        #
        # Coercer that will be run when the user retrieves a value.
        #
        attribute :coercer_out, Validation::CoercerOut
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
        attribute :call_proc, Proc
        #
        # A hash of named events the user has registered listeners for.
        # if !events[:on_set], there are no listeners for on_set.
        #
        attribute :events, Hash[Symbol => Event]
        attribute :required, boolean
      end
    end
    class SetType
      type.inline do
        attribute :item_type, Type
        attribute :singular, Symbol
      end
    end
    class TypeType
      type.inline do
        attribute :specialize_from, Type, :default => type_system.base_type
        attribute :reopen_on_call, boolean, :default => true
      end
    end
  end
end
