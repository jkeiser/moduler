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
      def coerce(value)
        if value.is_a?(Moduler::Facade::ArrayFacade)
          if value.type != self && element_type
            value = value.map { |value| element_type.to_raw(value) }
          else
            value = value.raw_write
          end
        elsif !value.nil?
          if value.respond_to?(:to_a)
            value = value.to_a
          else
            value = [ value ]
          end
          if element_type
            value = value.map { |value| element_type.to_raw(value) }
          end
        end
        super(value)
      end

      #
      # When the user requests the array, we give them a facade to protect the
      # values, assuming there is any index_type or element_type to protect.
      #
      def coerce_out(value)
        if value.is_a?(Lazy) || (value && (index_type || element_type))
          Facade::ArrayFacade.new(value, self)
        else
          value
        end
      end

      def new_facade(array)
        Facade::ArrayFacade.new(to_raw(array), self)
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
