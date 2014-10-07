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
      @coercers = []
      @coercers_out = []
      @default_value = NO_VALUE
      @events = {}
      super
    end

    attr_accessor :coercers
    attr_accessor :coercers_out
    attr_accessor :default_value
    attr_accessor :call_proc

    #
    # A hash of named events the user has registered listeners for.
    # if !events[:on_set], there are no listeners for on_set.
    #
    attr_reader :events

    #
    # Transform or validate the value before setting its raw value.
    #
    def coerce(value)
      if coercers && !value.is_a?(LazyValue)
        coercers.inject(value) { |result,coercer| coercer.coerce(result) }
      else
        value
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
      if value == NO_VALUE
        value = default_value
        if value.is_a?(LazyValue)
          cache = value.cache
          value = value.call
          if cache && cache_proc
            cache_proc.call(value)
          end
        end
      elsif value.is_a?(LazyValue)
        cache = value.cache
        value = coerce(value.call)
        if cache && cache_proc
          cache_proc.call(value)
        end
      end

      if value != NO_VALUE && coercers_out
        coercers_out.inject(value) { |result,coercer| coercer.coerce_out(result) }
      else
        value
      end
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
          coerce_out(context.set(coerce(block)))
        else
          coerce_out(context.get) { |value| context.set(value) }
        end
      elsif block
        raise "Both value and block passed to attribute!  Only one at a time accepted."
      else
        coerce_out(context.set(coerce(value)))
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
  end
end
