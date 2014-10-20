require 'moduler/facade/value_facade'

module Moduler
  module Facade
    class ArrayFacade < ValueFacade
      include Enumerable

      def to_s
        "ArrayFacade#{raw}"
      end
      def inspect
        "ArrayFacade:#{raw.inspect}"
      end
      def size
        raw.size
      end
      def each
        if block_given?
          raw.each { |value| yield from_raw(value) }
        else
          Enumerator.new do |y|
            raw.each { |value| y.yield from_raw(value) }
          end
        end
      end
      def each_with_index
        if block_given?
          raw.each_with_index { |value,index| yield from_raw(value), index_from_raw(index) }
        else
          Enumerator.new do |y|
            raw.each_with_index { |value,index| y.yield from_raw(value), index_from_raw(index) }
          end
        end
      end

      def [](index)
        if index.is_a?(Range)
          range = range_to_raw(index)
          result = raw[range_to_raw(index)]
          type.from_raw(result)
        else
          index = index_to_raw(index)
          from_raw(raw[index])
        end
      end
      def at(index)
        index = index_to_raw(index)
        from_raw(raw[index])
      end

      def []=(index, value)
        if index.is_a?(Range)
          index = range_to_raw(index)
          value = type.to_raw(value)
          raw_write[index] = value
          type.from_raw(value)
        else
          index = index_to_raw(index)
          value = to_raw(value)
          raw_write[index] = value
          from_raw(value)
        end
      end

      def <<(value)
        raw_write << to_raw(value)
        self
      end
      def unshift(value)
        raw_write.unshift(to_raw(value))
        self
      end
      def push(value)
        raw_write.push(to_raw(value))
        self
      end
      def shift
        from_raw(raw_write.shift)
      end
      def pop
        from_raw(raw_write.pop)
      end

      def insert(index, value)
        index = index_to_raw(index)
        value = to_raw(value)
        raw_write.insert(index, value)
        self
      end
      def delete_at(index)
        index = index_to_raw(index)
        from_raw(raw_write.delete_at(index))
      end

      def to_a
        # TODO don't copy raws unless there are lazy values
        raw.map { |value| from_raw(value) }
      end
      def ==(other)
        if other.is_a?(Array) || other.is_a?(ArrayFacade)
          to_a == other.to_a
        else
          false
        end
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

      def join(other)
        to_a.join(other)
      end

      def range_to_raw(index)
        type.index_type ? Range.new(type.index_type.to_raw(index.begin), type.index_type.to_raw(index.end)) : index
      end

      def index_to_raw(index)
        type.index_type ? type.index_type.to_raw(index)   : index
      end

      def index_from_raw(index)
        type.index_type ? type.index_type.from_raw(index) : index
      end

      def to_raw(value)
        type.element_type ? type.element_type.to_raw(value) : value
      end

      def from_raw(value)
        result = type.element_type ? type.element_type.from_raw(value) : value
        # TODO this code will almost certainly go away once we get something similar into structs
        if !result.frozen? && @raw.is_a?(Lazy)
          @raw.ensure_writeable
        end
        result
      end
    end
  end
end
