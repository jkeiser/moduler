require 'moduler/specializable'
require 'moduler/lazy_value'
require 'moduler/constants'

module Moduler
  module Base
    class Type
      include Moduler::Specializable

      require 'moduler/emitter'

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
        true
      end

      #
      # Transform or validate the value before setting its raw value.
      #
      def coerce(value)
        value
      end

      #
      # Transform or validate the value before getting its raw value.
      #
      # ==== Returns
      # The output value.
      #
      def coerce_out(value, &cache_proc)
        value = raw_value(value, &cache_proc)
        value == NO_VALUE ? nil : value
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
            # TODO this is a terrible idea.  Classes, for example, should not be dup'd.
            # Narrow it down to things people expect to be value-ish (hash,array,set?)
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
      # Standard call semantics: +blah+ is get, +blah value+ is set,
      # +blah do ... end+ is "set to proc"
      #
      def call(context, *args, &block)
        # Default "call" semantics (get/set)
        default_call(context, *args, &block)
      end

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
