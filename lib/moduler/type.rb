require 'moduler'
require 'moduler/lazy_value'
require 'moduler/event'
require 'moduler/base/type'

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
    def initialize(*args, &block)
      @hash = { :events => {} }
      @default = NO_VALUE
      super
    end

    #
    # Core DSL
    #
    def raw_value(value, &cache_proc)
      if value == NO_VALUE
        raw_default(&cache_proc)
      else
        super
      end
    end

    def raw_default(&cache_proc)
      value = @default
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

    #
    # The proc to instance_eval on +call+.
    #
    def call(context, *args, &block)
      if call_proc
        if block
          context.define_method(:call_proc, call_proc)
          result = context.call_proc(context, *args, &block)
        else
          result = context.instance_exec(context, *args, &call_proc)
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

    def self.type_type
      Moduler::Type::TypeType.empty
    end
    require 'moduler/type/type_type'

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
    def default(*args, &block)
      if args.size == 0 && !block && @default == NO_VALUE
        NO_VALUE
      else
        default_call(DefaultValueContext.new(self), *args, &block)
      end
    end
    def default=(value)
      @default = coerce(value)
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
    # Used in default
    #
    class DefaultValueContext
      def initialize(type)
        @type = type
      end
      def set(value)
        @type.instance_variable_set(:@default, value)
      end
      def get
        if @type.instance_variable_defined?(:@default)
          @type.instance_variable_get(:@default)
        else
          NO_VALUE
        end
      end
    end

    require 'moduler/type/validator/compound_validator'
    require 'moduler/type/validator/equal_to'
    require 'moduler/type/validator/kind_of'
    require 'moduler/type/validator/regexes'
    require 'moduler/type/validator/cannot_be'
    require 'moduler/type/validator/respond_to'
    require 'moduler/type/validator/validate_proc'

    #
    # Pure DSL methods
    #
    def lazy(cache=true, &block)
      Moduler::LazyValue.new(cache, &block)
    end

    # TODO move the pure DSL into a module or something so it can be mixed
    def equal_to(*values)
      add_validator(Moduler::Type::Validator::EqualTo.new(*values))
    end
    def kind_of(*kinds)
      add_validator(Moduler::Type::Validator::KindOf.new(*kinds))
    end
    def regex(*regexes)
      add_validator(Moduler::Type::Validator::Regexes.new(*regexes))
    end
    def cannot_be(*truthy_things)
      add_validator(Moduler::Type::Validator::CannotBe.new(*truthy_things))
    end
    def respond_to(*method_names)
      add_validator(Moduler::Type::Validator::RespondTo.new(*method_names))
    end
    def callbacks(callbacks)
      add_validator(ModulerType::Validator::ValidateProc.new do |value|
        callbacks.select do |message, callback|
          callback.call(value) != true
        end.map do |message, callback|
          validation_failure("Value #{value} #{message}!")
        end
      end)
    end
    def add_validator(validator)
      if @validator.is_a?(Moduler::Type::Validator::CompoundValidator)
        @validator.validators << validator
      elsif @validator
        @validator = Moduler::Type::Validator::CompoundValidator(@validator, validator)
      else
        @validator = validator
      end
    end

    attribute :required#, :equal_to => [true, false], :default => false

    #
    # A hash of named events the user has registered listeners for.
    # if !events[:on_set], there are no listeners for on_set.
    #
    attribute :events#
    # TODO make the dup stuff work
    attribute :events, :default => LazyValue.new { {}.dup }

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
  end
end

require 'moduler/type/hash_type'
require 'moduler/type/array_type'
require 'moduler/type/set_type'
