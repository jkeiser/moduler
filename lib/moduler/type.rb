require 'moduler/guard'
require 'moduler/lazy_value'

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
      @events = {}
    end

    attr_reader :coercers
    attr_reader :coercers_out

    #
    # Transform or validate the value before setting its raw value.
    #
    def coerce(value)
      if coercers && !value.is_a?(LazyValue)
        coercers.inject(value) { |result,coercer| coercer.coerce(value) }
      else
        value
      end
    end

    #
    # Transform or validate the value before getting its raw value.
    #
    def coerce_out(value, &cache_proc)
      if value.is_a?(LazyValue)
        cache = value.cache
        value = coerce_in(value.call)
        if cache && cache_proc
          cache_proc.call(value)
        end
      end
      if coercers_out
        coercers_out.inject(value) { |result,coercer| coercer.coerce_in(value) }
      else
        value
      end
    end

    #
    # If the value is missing, this method is called to give the opportunity
    # to return a default value (and optionally to set the value).
    #
    def get_default(&cache_proc)
      value = self.class.default_value
      if value.is_a?(LazyValue)
        cache = value.cache
        value = coerce_in(value.call)
        if cache && cache_proc
          cache_proc.call(value)
        end
      end

      coerce_out(value)
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
          context.set(block)
        else
          context.get
        end
      elsif block
        raise "Both value and block passed to attribute!  Only one at a time accepted."
      else
        context.set(value)
      end
    end

    #
    # A hash of named events the user has registered listeners for.
    # if !events[:on_set], there are no listeners for on_set.
    #
    attr_reader :events

    #
    # Add a listener for the given event.
    #
    def add_listener(event, &block)
      events[event] ||= possible_events[event].new
      events[event].add_listener(&block)
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
