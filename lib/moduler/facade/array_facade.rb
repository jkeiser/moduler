require 'moduler/facade'
require 'moduler/specializable'

module Moduler
  module Facade
    class ArrayFacade
      include Facade
      include Enumerable

      def initialize(array, type)
        @array = array
        @type = type
      end

      attr_reader :array
      attr_reader :type

      def size
        array.size
      end
      def [](index)
        index = type.coerce_key(index)
        type.coerce_value_out(index, index < array.size && index >= -array.size ? self[index] : NO_VALUE)
      end
      def []=(index, value)
        index = type.coerce_key(index)
        self[index] = result = type.coerce_value(index, value)
        result = type.coerce_value_out(index, result)
        if type.events[:on_set]
          type.events[:on_set].fire(:on_set, result)
        end
        result
      end
      def delete_at(index)
        index = type.coerce_key(index)
        if index < array.size && index >= -array.size
          type.coerce_value_out(index, array.delete_at(index))
        else
          nil
        end
      end
      def each
        array.each_with_index do |value, index|
          yield type.coerce_value_out(index, value)
        end
      end
      def each_with_index
        array.each_with_index do |value, index|
          yield type.coerce_value_out(index, value), index_out(index)
        end
      end
      alias :each_pair :each
    end
  end
end
