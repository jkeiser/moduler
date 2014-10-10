# Enough stuff to get the "attribute" DSL up and running inside types themselves
# (essentially a bootstrap)

require 'moduler/specializable'
require 'moduler/attributable'
require 'moduler/lazy_value'
require 'moduler/base/attribute'
require 'moduler/base/value_context'
require 'moduler/validation/coercer'
require 'moduler/validation/coercer_out'
require 'moduler/validation/validator'
require 'moduler/event'
require 'moduler/errors'

module Moduler
  module Base
    class Type
      include Moduler::Specializable
      include Moduler::Attributable

      def self.type_type
        Base::Type::TypeType.empty
      end

      def self.empty
        @empty ||= self.new
      end

      def self.emit_attribute(target, name, *args, &block)
        if args.size > 0 || block
          type = type_type.call(ValueContext.new, *args, &block)
          Attribute.emit_attribute(target, name, type == NO_VALUE ? nil : type)
        else
          Attribute.emit_attribute(target, name)
        end
      end

      def self.attribute(name, *args, &block)
        emit_attribute(self, name, *args, &block)
      end

      def emit_attribute(target, name)
        Attribute.emit_attribute(target, name, self)
      end

      #
      # Transform or validate the value before setting its raw value.
      #
      def coerce(value)
        if value.is_a?(LazyValue)
          # Leave lazy values alone until we retrieve them
          value
        else
          validate(value) if validator
          coercer ? coercer.coerce(value) : value
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
        if validator
          result = validator.validate(value)
          if result.is_a?(Array)
            if result.size > 0
              raise ValidationFailed.new(result)
            end
          elsif result.is_a?(Hash) || result.is_a?(String)
            raise ValidationFailed.new([result])
          elsif result == false
            raise ValidationFailed.new([ Validation::Validator.default_validation_failure(validator, value) ])
          end
        end
      end

      #
      # Transform or validate the value before getting its raw value.
      #
      # ==== Returns
      # The out value, or NO_VALUE.  You will only ever get back NO_VALUE if you
      # pumped NO_VALUE in.  (And even then, you may get a default value instead.)
      #
      def coerce_out(value, &cache_proc)
        value = raw_value(value, &cache_proc)

        if value != NO_VALUE && coercer_out
          value = coercer_out.coerce_out(value)
        end
        value
      end

      def raw_value(value, &cache_proc)
        if value == NO_VALUE
          raw_default(&cache_proc)

        elsif value.is_a?(LazyValue)
          cache = value.cache
          value = coerce(value.call)
          if cache && cache_proc
            cache_proc.call(value)
          end
          value

        else
          value
        end
      end

      def raw_default(&cache_proc)
        value = @hash[:default] || NO_VALUE
        if value.is_a?(LazyValue)
          cache = value.cache
          value = coerce(value.call)
          if cache && cache_proc
            cache_proc.call(value)
          end
        end
        value
      end

      #
      # The proc to instance_eval on +call+.
      #
      def call(context, *args, &block)
        if @hash[:call_proc]
          if block
            context.define_method(:call_proc, @hash[:call_proc])
            result = context.call_proc(context, *args, &block)
          else
            result = context.instance_exec(context, *args, &@hash[:call_proc])
          end
          if result == NOT_HANDLED
            result = default_call(context, *args, &block)
          end
          result
        else
          # Default "call" semantics (get/set)
          default_call(context, *args, &block)
        end
      end

      #
      # Standard call semantics: +blah+ is get, +blah value+ is set,
      # +blah do ... end+ is "set to proc"
      #
      def default_call(context, value = NOT_PASSED, &block)
        if value == NOT_PASSED
          if block
            value = block
          else
            return coerce_out(context.get) { |value| context.set(value) }
          end
        elsif block
          raise ArgumentError, "Both value and block passed to attribute!  Only one at a time accepted."
        end

        value = coerce(value)
        value = context.set(value)
        if value.is_a?(LazyValue)
          fire_on_set_raw(value)
        else
          value = coerce_out(value) { |value| context.set(value) }
          fire_on_set(value)
        end
        value
      end

      #
      # Fire the on_set handler.
      #
      # ==== Arguments
      #
      # [value]
      # The value that was set.
      # [is_raw]
      # If +true+, the value is considered the *stored* value and will be coerce_out'd
      # before the user gets it.  If +false+, the value is considered the coerced
      # value, and no coercion will happen.
      #
      # ==== Block
      #
      # The passed block is passed the type as an argument and is expected to
      # return an OnSetContext instance.
      #
      # ==== Example
      #
      #   type.fire_on_set(@hash[:foo])
      #
      def fire_on_set(value, is_raw=false)
        if events && events[:on_set]
          events[:on_set].fire(OnSetContext.new(self, value, is_raw))
        end
      end

      def fire_on_set_raw(value)
        fire_on_set(value, true)
      end

      class OnSetContext
        def initialize(type, value, is_raw)
          @type = type
          @value = value
          @is_raw = is_raw
        end

        attr_reader :type
        def value
          if @is_raw
            @value = type.coerce_out(@value)
            @is_raw = false
          end
          @value
        end
      end

      #
      # Add a listener for the given event.
      #
      def register(event, &block)
        events[event] ||= possible_events[event].new(event)
        events[event].register(&block)
      end

      #
      # The list of possible events for this Type.
      #
      # By default, this is just the list of possible_events from the Type class.
      #
      def possible_events
        self.class.possible_events
      end

      #
      # The list of possible events for types in this Type class.
      #
      def self.possible_events
        {
          :on_set => Event
        }
      end

      def add_validator(validator)
        if @validator.is_a?(Moduler::Validation::Validator::CompoundValidator)
          @validator.validators << validator
        elsif @validator
          @validator = Moduler::Validation::Validator::CompoundValidator(@validator, validator)
        else
          @validator = validator
        end
      end

      #
      # A hash of named events the user has registered listeners for.
      # if !events[:on_set], there are no listeners for on_set.
      #
      attribute :events

      #
      # Coercer that will be run when the user gives us a value to store.
      #
      attribute :coercer

      #
      # A Validator to validate the value.  Will be run on the value before coercion.
      #
      attribute :validator

      #
      # Coercer that will be run when the user retrieves a value.
      #
      attribute :coercer_out

      #
      # The default value gets set the same way as the value would--you can use
      # the same expressions you would otherwise.
      #
      # TODO when call_proc is around, maybe we can make this better ...
      def default(*args, &block)
        context = Attribute::StructFieldContext.new(@hash, :default)
        # Short circuit "no default value for default" so we don't loop
        if args.size == 0 && !block && context.get == NO_VALUE
          NO_VALUE
        else
          default_call(context, *args, &block)
        end
      end
      def default=(value)
        @hash[:default] = coerce(value)
      end

      #
      # Interlude
      #
      # This is where we load the other types in prep for being able to use attributes.
      #
      require 'moduler/base/type/type_type'
      require 'moduler/base/type/hash_type'
      require 'moduler/base/type/array_type'
      require 'moduler/base/type/set_type'
      require 'moduler/base/type/struct_type'

      #
      # Redefinition
      #
      attribute :call_proc, Proc
      attribute :coercer, Validation::Coercer
      attribute :validator, Validation::Validator
      attribute :coercer_out, Validation::CoercerOut
      attribute :events, Hash[Symbol => Event]
    end
  end
end
