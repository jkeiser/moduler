require 'moduler/base/type'
require 'moduler/facade/array_facade'

module Moduler
  module Base
    class ArrayType < Type
      def raw_default
        defined?(@default) ? @default : []
      end

      #
      # We store arrays internally as arrays, and slap facades on them when the
      # user requests them.
      #
      def coerce(value, context)
        if value.is_a?(Moduler::Facade::ArrayFacade)
          if value.type != self && element_type
            value = value.map { |value| element_type.to_raw(value, context) }
          else
            value = value.raw(context)
          end
        elsif !value.nil?
          if value.respond_to?(:to_a)
            value = value.to_a
          else
            value = [ value ]
          end
          if element_type
            value = value.map { |value| element_type.to_raw(value, context) }
          end
        end
        super
      end

      #
      # When the user requests the array, we give them a facade to protect the
      # values, assuming there is any index_type or element_type to protect.
      #
      def coerce_out(value, context)
        if value.is_a?(Value) || (value && (index_type || element_type))
          Facade::ArrayFacade.new(value, self, context)
        else
          value
        end
      end

      def clone_value(value)
        if !value
          value
        elsif element_type
          value.map { |item| element_type.clone_value(item) }
        else
          value.dup
        end
      end

      def emit(parent=nil, name=nil)
        index_type.emit(parent, name) if index_type
        element_type.emit(parent, name) if element_type
      end
    end
  end
end
