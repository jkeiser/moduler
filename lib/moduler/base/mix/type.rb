require 'moduler/specializable'
require 'moduler/attributable'

module Moduler
  module Base
    module Mix
      module Type
        include Moduler::Specializable
        include Moduler::Attributable

        def inline(&block)
          raise "Must pass block to inline" if !block
          target = block.binding.eval('self')
          instance_eval(&block)
          emit_to(target)
        end

        def emit_attribute(target, name)
          Moduler::Base::Attribute.emit_attribute(target, name, self)
        end

        #
        # Tell whether call() / coerce() can be skipped if the user asks for a
        # value.  Caller will still need to handle defaults and lazy values (which
        # require you to do call or coerce_out).
        #
        def raw_get?
          !coercer_out && !call_proc
        end

        #
        # TODO we need a has_value? for skip_coercion_if that says "will it give
        # me a value?" and includes default.  To do that, types need types.  Yay?
        #
        def is_set?(name)
          @hash.has_key?(name)
        end

        def reset(name)
          @hash.delete(name)
        end

        #
        # Transform or validate the value before setting its raw value.
        #
        def coerce(value)
          if is_set?(:skip_coercion_if) && skip_coercion_if == value
            return value
          end

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
          if is_set?(:skip_coercion_if) && skip_coercion_if == value
            return
          end

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
        # The output value.
        #
        def coerce_out(value, &cache_proc)
          value = coerce_out_base(value, &cache_proc)
          value == NO_VALUE ? nil : value
        end

        #
        # Like coerce_out, but can return NO_VALUE if there is no default.
        #
        # ==== Returns
        # The out value, or NO_VALUE.  You will only ever get back NO_VALUE if you
        # pumped NO_VALUE in.  (And even then, you may get a default value instead.)
        #
        def coerce_out_base(value, &cache_proc)
          value = raw_value(value, &cache_proc)
          if value != NO_VALUE && coercer_out && !(skip_coercion_if == value && is_set?(:skip_coercion_if))
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
        # The default value gets set the same way as the value would--you can use
        # the same expressions you would otherwise.
        #
        def default(*args, &block)
          context = Attribute::StructFieldContext.new(@hash, :default)
          # Short circuit "no default value for default" so we don't loop
          if args.size == 0 && !block && context.get == NO_VALUE
            nil
          else
            call(context, *args, &block)
          end
        end
        def default=(value)
          @hash[:default] = coerce(value)
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
          type_system.possible_events
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
      end
    end
  end
end
