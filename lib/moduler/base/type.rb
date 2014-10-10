# Enough stuff to get the "attribute" DSL up and running inside types themselves
# (essentially a bootstrap)

require 'moduler/specializable'
require 'moduler/attributable'
require 'moduler/lazy_value'
require 'moduler/base/attribute'
require 'moduler/base/value_context'

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
        type = type_type.call(ValueContext.new, *args, &block)
        Attribute.emit_attribute(target, name, type == NO_VALUE ? nil : type)
      end

      def self.attribute(name, *args, &block)
        emit_attribute(self, name, *args, &block)
      end

      def emit_attribute(target, name)
        Attribute.emit_attribute(target, name, self)
      end

      def coerce(value)
        value
      end

      def coerce_out(value)
        value
      end

      def raw_value(value, &cache_proc)
        if value.is_a?(LazyValue)
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

      def call(context, *args, &block)
        default_call(context, *args, &block)
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
      end

      def fire_on_set_raw(value)
      end
    end
  end
end

require 'moduler/base/type/type_type'
require 'moduler/base/type/hash_type'
require 'moduler/base/type/array_type'
require 'moduler/base/type/set_type'
require 'moduler/base/type/struct_type'
