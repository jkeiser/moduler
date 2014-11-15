require 'moduler/facade'

module Moduler
  module Facade
    class ArrayFacade
      include Facade
      include Enumerable

      def to_s
        "ArrayFacade#{raw_read}"
      end
      def inspect
        "ArrayFacade:#{raw_read.inspect}"
      end
      def size
        raw_read.size
      end
      def empty?
        raw_read.empty?
      end
      def each
        if block_given?
          raw_read.each { |value| yield from_raw(value) }
        else
          Enumerator.new do |y|
            raw_read.each { |value| y.yield from_raw(value) }
          end
        end
      end
      def each_with_index
        if block_given?
          raw_read.each_with_index { |value,index| yield from_raw(value), index_from_raw(index) }
        else
          Enumerator.new do |y|
            raw_read.each_with_index { |value,index| y.yield from_raw(value), index_from_raw(index) }
          end
        end
      end

      def [](index)
        if index.is_a?(Range)
          range = range_to_raw(index)
          result = raw_read[range_to_raw(index)]
          type.from_raw(result, context)
        else
          index = index_to_raw(index)
          from_raw(raw_read[index])
        end
      end
      def at(index)
        index = index_to_raw(index)
        from_raw(raw_read[index])
      end

      def []=(index, value)
        if index.is_a?(Range)
          index = range_to_raw(index)
          value = type.to_raw(value, context)
          raw[index] = value
          type.from_raw(value, context)
        else
          index = index_to_raw(index)
          value = to_raw(value)
          raw[index] = value
          from_raw(value)
        end
      end

      def <<(value)
        raw << to_raw(value)
        self
      end
      def unshift(value)
        raw.unshift(to_raw(value))
        self
      end
      def push(value)
        raw.push(to_raw(value))
        self
      end
      def shift
        from_raw(raw.shift)
      end
      def pop
        from_raw(raw.pop)
      end

      def insert(index, value)
        index = index_to_raw(index)
        value = to_raw(value)
        raw.insert(index, value)
        self
      end
      def delete_at(index)
        index = index_to_raw(index)
        from_raw(raw.delete_at(index))
      end

      def to_a
        # TODO don't copy raws unless there are lazy values
        raw_read.map { |value| from_raw(value) }
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

      protected

      def range_to_raw(index)
        type.index_type ? Range.new(type.index_type.to_raw(index.begin, context), type.index_type.to_raw(index.end, context)) : index
      end

      def index_to_raw(index)
        type.index_type ? type.index_type.to_raw(index, context) : index
      end

      def index_from_raw(index)
        result = type.index_type ? type.index_type.from_raw(index, context) : index
        child_value(result)
      end

      def to_raw(value)
        type.element_type ? type.element_type.to_raw(value, context) : value
      end

      def from_raw(value)
        result = type.element_type ? type.element_type.from_raw(value, context) : value
        child_value(result)
      end
    end
  end
end
