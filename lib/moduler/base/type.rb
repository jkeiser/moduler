require 'moduler/lazy/value'
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

      def to_raw(value)
        value.is_a?(Lazy) ? value : coerce(value)
      end

      def from_raw(value)
        coerce_out(value.is_a?(Lazy) ? coerce(value.get) : value)
      end

      def raw_default
        @default
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
      def coerce_out(value)
        value
      end

      def construct_raw(value=NOT_PASSED, &block)
        if value == NOT_PASSED
          if block
            value = block
          else
            raise ArgumentError, "Neither value nor block passed to set attribute!  Pass one or the other."
          end
        elsif block
          raise ArgumentError, "Both value and block passed to set attribute!  Only one at a time accepted."
        end

        if !value.is_a?(Lazy)
          value = coerce(value)
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
          @default = construct_raw(*args, &block)
        end
        from_raw(@default)
      end
      def default=(value)
        @default = to_raw(value)
      end
    end
  end
end

require 'moduler/base/type_attributes'
