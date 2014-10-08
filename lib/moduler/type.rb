require 'moduler'
require 'moduler/specializable'
require 'moduler/lazy_value'
require 'moduler/event'

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
  # - PathSetType: governs a type
  #
  class Type
    include Moduler::Specializable

    def initialize(*args, &block)
      @default_value = NO_VALUE
      @events = {}
      super
    end

    #
    # Base type methods
    #

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
        elsif result.is_a?(Hash)
          raise ValidationFailed.new([result])
        elsif result == false
          raise ValidationFailed.new([ Validator.default_validation_failure(validator, value) ])
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
        raw_default_value(&cache_proc)

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

    def raw_default_value(&cache_proc)
      value = @default_value
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
      if call_proc
        if block
          context.define_method(:call_proc, call_proc)
          context.call_proc(*args, &block)
        else
          context.instance_exec(*args, &call_proc)
        end
      else
        # Default "call" semantics
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
          value = context.get
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
    # Core DSL
    #

    #
    # Proc to be called when this value is call()ed.  Takes place of the default
    # get/set algorithm when the user says foo.bar <value> or foo.bar do ... end
    # or even foo.bar <values> do ... end
    #
    attr_accessor :call_proc

    #
    # Coercer that will be run when the user gives us a value to store.
    #
    attr_accessor :coercer

    #
    # Coercer that will be run when the user retrieves a value.
    #
    attr_accessor :coercer_out

    #
    # A Validator to validate the value.  Will be run on the value before coercion.
    #
    attr_accessor :validator

    #
    # The default value gets set the same way as the value would--you can use
    # the same expressions you would otherwise.
    #
    def default_value(*args, &block)
      if args.size == 0 && !block && @default_value == NO_VALUE
        NO_VALUE
      else
        default_call(DefaultValueContext.new(self), *args, &block)
      end
    end
    def default_value=(value)
      @default_value = coerce(value)
    end

    #
    # A hash of named events the user has registered listeners for.
    # if !events[:on_set], there are no listeners for on_set.
    #
    attr_reader :events

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

    #
    # Fire the on_set handler.
    #
    # ==== Block
    #
    # The passed block is passed the type as an argument and is expected to
    # return an OnSetContext instance.
    #
    # ==== Example
    #
    #   type.fire_on_set_raw(@hash[:foo])
    #
    def fire_on_set(value, is_raw=false)
      if events[:on_set]
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
    # Used in default_value
    #
    class DefaultValueContext
      def initialize(type)
        @type = type
      end
      def set(value)
        @type.instance_variable_set(:@default_value, value)
      end
      def get
        if @type.instance_variable_defined?(:@default_value)
          @type.instance_variable_get(:@default_value)
        else
          NO_VALUE
        end
      end
    end
  end
end
