require 'moduler/value'
require 'moduler/constants'

module Moduler
  module Base
    class Type
      def clone_value(value)
        begin
          value.dup
        rescue TypeError
          value
        end
      end

      def to_raw(value, context)
        value.is_a?(Value) ? value : coerce(value, context)
      end

      def from_raw(value, context)
        result = coerce_out(value, context)
        result
      end

      def raw_default
        @default
      end

      #
      # Transform or validate the value before setting its raw value.
      #
      def coerce(value, context)
        value
      end

      #
      # Transform or validate the value before getting its raw value.
      #
      # ==== Returns
      # The output value.
      #
      # TODO make this coerce_out lazy values, or don't unwrap at all ...
      def coerce_out(value, context)
        # By default, we unwrap lazy values and return a writeable raw value
        if value.is_a?(Value)
          coerce(value.raw(context), context)
        else
          value
        end
      end

      def construct_raw(context, value=NOT_PASSED, &block)
        if value == NOT_PASSED
          if block
            value = block
          else
            raise ArgumentError, "Neither value nor block passed to construct attribute!  Pass one or the other."
          end
        elsif block
          raise ArgumentError, "Both value and block passed to construct attribute!  Only one at a time accepted."
        end

        if !value.is_a?(Value)
          value = coerce(value, context)
        end
        value
      end

      #
      # The default value gets set the same way as the value would--you can use
      # the same expressions you would otherwise.
      #
      def default(*args, &block)
        # Short circuit "no default value for default" so we don't loop
        if args.size != 0 || block
          @default = construct_raw(self, *args, &block)
        else
          from_raw(raw_default, self)
        end
      end
      def default=(value)
        @default = to_raw(value, self)
      end

      def emit(parent=nil, name=nil)
      end
    end
  end
end

require 'moduler/base/type_attributes'
