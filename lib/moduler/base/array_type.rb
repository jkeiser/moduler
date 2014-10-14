require 'moduler/base/type'
require 'moduler/event'
require 'moduler/facade/array_facade'

module Moduler
  module Base
    class ArrayType < Type
      def raw_get?
        false
      end

      #
      # We store arrays internally as arrays, and slap facades on them when the
      # user requests them.
      #
      def coerce(array)
        if array.is_a?(Moduler::Facade::ArrayFacade)
          array = array.array
        elsif element_type
          array = array.map { |value| coerce_value(nil, value) }
        else
          array = array.to_a
        end
        super(array)
      end

      #
      # When the user requests the array, we give them a facade to protect the
      # values, assuming there is any index_type or element_type to protect.
      #
      def coerce_out(array, &cache_proc)
        array = coerce_out_base(array, &cache_proc)
        if array == NO_VALUE
          array = []
          cache_proc.call(array)
        end

        if index_type || element_type
          Moduler::Facade::ArrayFacade.new(array, self)
        else
          array
        end
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

      def clone_value(value)
        if !value
          value
        elsif element_type
          value.map { |item| element_type.clone_value(item) }
        else
          value.dup
        end
      end

      def possible_events
        super.merge(:on_array_updated => Event)
      end
    end
  end
end
