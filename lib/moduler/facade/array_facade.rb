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

      def ==(other)
        if !(other.is_a?(ArrayFacade) || other.is_a?(Array))
          return false
        end

        return false if size != other.size
        return false if zip(other).any? { |a,b| a != b }
        return true
      end

      def size
        array.size
      end
      def each
        array.each_with_index do |value, index|
          yield type.coerce_value_out(index, value)
        end
      end
      def each_with_index
        array.each_with_index do |value, index|
          yield type.coerce_value_out(index, value), type.coerce_key_out(index)
        end
      end
      def [](index)
        if index.is_a?(Range)
          index = type.coerce_key_range(index)
          result = array[index]
          result ? type.coerce_out(result) : result
        else
          index = type.coerce_key(index)
          type.coerce_value_out(index, array[index])
        end
      end

      def []=(index, value)
        if index.is_a?(Range)
          index = type.coerce_key_range(index)
          result = type.coerce(value)
          @array[index] = result
          result = type.coerce_out(result)
        else
          index = type.coerce_key(index)
          result = type.coerce_value(index, value)
          @array[index] = result
          result = type.coerce_value_out(index, result)
        end
        result
      end

      def <<(value)
        value = type.coerce_value(nil, value)
        type.coerce_out( @array << value )
      end
      def unshift(value)
        value = type.coerce_value(nil, value)
        type.coerce_out( @array.unshift(value) )
      end
      def push(value)
        value = type.coerce_value(nil, value)
        type.coerce_out( @array.push(value) )
      end
      def shift
        type.coerce_value_out(nil, @array.shift)
      end
      def pop
        type.coerce_value_out(nil, @array.pop)
      end

      def insert(index, value)
        index = type.coerce_key(index)
        value = type.coerce_value(index, value)
        type.coerce_out( @array.insert(index, value) )
      end

      def delete_at(index)
        index = type.coerce_key(index)
        type.coerce_value_out(index, array.delete_at(index))
      end
    end
  end
end
