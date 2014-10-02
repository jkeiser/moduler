require 'moduler/type'
require 'moduler/facade/array_facade'

module Moduler
  class Type
    class ArrayType < Type
      attr_accessor :index_type
      attr_accessor :element_type

      def facade_class
        ArrayFacade
      end

      def coerce(array)
        if array.is_a?(facade_class)
          array = array.raw
        end
        super(array)
      end

      def coerce_out(array)
        facade_class.new(super, self)
      end

      def coerce_key(index)
        index_type ? index_type.coerce(index) : index
      end

      def coerce_item(raw_index, value)
        element_type ? element_type.coerce(value) : value
      end

      def coerce_key_out(index)
        index_type ? index_type.coerce_out(index) : index
      end

      def coerce_item_out(raw_index, value)
        element_type ? element_type.coerce_out(value) : value
      end

      def item_type_for(raw_index)
        element_type
      end

      def self.possible_events
        super.merge(:on_array_updated => Event)
      end
    end
  end
end
