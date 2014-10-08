require 'moduler/facade'

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
      def each
        if block_given?
          array.each_with_index do |value, index|
            yield type.coerce_value_out(index, value)
          end
        else
          Enumerator.new do |y|
            array.each_with_index do |value, index|
              y.yield type.coerce_value_out(index, value)
            end
          end
        end
      end
      def each_with_index
        if block_given?
          array.each_with_index do |value, index|
            yield type.coerce_value_out(index, value), type.coerce_key_out(index)
          end
        else
          Enumerator.new do |y|
            array.each_with_index do |value, index|
              y.yield type.coerce_value_out(index, value), type.coerce_key_out(index)
            end
          end
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
      def at(index)
        index = type.coerce_key(index)
        type.coerce_value_out(index, array[index])
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

      def to_a
        # TODO don't copy arrays unless there are lazy values/coercer_outs
        array.map { |value| type.coerce_value_out(nil, value) }
      end
      def ==(other)
        to_a == other.to_a
      end
      def &(other)
        to_a & other.to_a
      end
      def |(other)
        to_a | other.to_a
      end
      def +(other)
        to_a + other.to_a
      end
      def -(other)
        to_a - other.to_a
      end

      def assoc(obj)
        if type.element_type.respond_to?(:coerce_value)
          obj = type.element_type.coerce_value(nil, obj)
        end
        type.coerce_value_out(array.assoc(obj))
      end

      def bsearch(&block)
        result = array.bsearch { |v| block.call(type.coerce_value_out(v)) }
        type.coerce_out(result)
      end

      def clear
        array.clear
        type.coerce_out(array)
      end
    end
  end
end
