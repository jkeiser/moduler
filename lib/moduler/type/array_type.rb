require 'moduler/type'
require 'moduler/facade/array_facade'

module Moduler
  class Type
    class ArrayType < Type
      attr_accessor :index_type
      attr_accessor :element_type

      def facade_class
        Moduler::Facade::ArrayFacade
      end

      def restore_facade(raw_value)
        facade_class.new(raw_value, self)
      end

      def new_facade(value)
        facade_class.new(coerce(value), self)
      end

      def coerce(array)
        if array.is_a?(facade_class)
          array = array.raw
        else
          array = array.map { |value| coerce_value(nil, value) }
        end
        super(array)
      end

      def coerce_out(array)
        facade_class.new(super, self)
      end

      def coerce_key(index)
        if index_type
          index_type.coerce(index)
        else
          index
        end
      end

      def coerce_key_range(range)
        if index_type
          Range.new(index_type.coerce(range.begin), index_type.coerce(range.end))
        else
          range
        end
      end

      def coerce_value(raw_index, value)
        element_type ? element_type.coerce(value) : value
      end

      def coerce_key_out(index)
        index_type ? index_type.coerce_out(index) : index
      end

      def coerce_value_out(raw_index, value)
        result = element_type ? element_type.coerce_out(value) : value
        result == NO_VALUE ? nil : result
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
