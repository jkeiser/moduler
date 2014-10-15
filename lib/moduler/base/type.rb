require 'moduler/specializable'
require 'moduler/lazy_value'
require 'moduler/constants'

module Moduler
  module Base
    class Type
      include Moduler::Specializable

      require 'moduler/emitter'

      Moduler::Emitter::StructEmitter.new(nil, self).instance_eval do
        emit_typeless_get_set_field(:target)
        emit_typeless_get_set_field(:coercer_out)
        emit_typeless_get_set_field(:coercer)
        emit_typeless_get_set_field(:validator)
        emit_typeless_get_set_field(:call_proc)
        emit_typeless_get_set_field(:skip_coercion_if)
      end

      def clone_value(value)
        begin
          value.dup
        rescue TypeError
          value
        end
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
          coercer ? coercer.coerce(value) : value
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
        value = @default || NO_VALUE
        if value.is_a?(LazyValue)
          cache = value.cache
          value = instance_eval(&value)
          value = coerce(value)
        elsif value != NO_VALUE
          # We dup defaults when we copy them out.
          begin
            # Some things cannot be dup'd, and you won't know this till after the fact
            # because all values implement dup
            value = value.dup
          rescue TypeError
          end
        end

        if value != NO_VALUE && cache && cache_proc
          cache_proc.call(value)
        end

        value
      end

      #
      # The proc to instance_eval on +call+.
      #
      def call(context, *args, &block)
        if @call_proc
          if block
            context.define_method(:call_proc, @call_proc)
            result = context.call_proc(context, *args, &block)
          else
            result = context.instance_exec(context, *args, &@call_proc)
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
        if !value.is_a?(LazyValue)
          value = coerce_out(value) { |value| context.set(value) }
        end
        value
      end

      #
      # The default value gets set the same way as the value would--you can use
      # the same expressions you would otherwise.
      #
      def default(*args, &block)
        # Short circuit "no default value for default" so we don't loop
        if args.size == 0 && !block && !defined?(@default)
          nil
        else
          call(ValueContext.new(@default) { |v| @default = v }, *args, &block)
        end
      end
      def default=(value)
        @default = coerce(value)
      end
    end
  end
end

require 'moduler/base/type_attributes'
