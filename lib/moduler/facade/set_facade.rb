require 'moduler/facade/value_facade'

module Moduler
  module Facade
    #
    # Slaps a set interface on top of the set value (which subclasses can
    # override).
    #
    class SetFacade < ValueFacade
      include Enumerable

      def ==(other)
        if other.is_a?(Set) || other.is_a?(SetFacade)
          to_set == other.to_set
        else
          false
        end
      end
      def to_set
        each.to_set
      end
      def size
        raw.size
      end
      def to_a
        raw.map { |item| from_raw(item) }
      end
      def include?(item)
        raw.include?(to_raw(item))
      end
      def member?(item)
        raw.member?(to_raw(item))
      end
      def add(item)
        raw_write.add(to_raw(item))
        self
      end
      def add?(item)
        raw_write.add?(to_raw(item)) ? self : nil
      end
      def <<(item)
        raw_write << to_raw(item)
        self
      end
      def delete(item)
        raw_write.delete(to_raw(item))
        self
      end
      def each
        if block_given?
          raw.each { |item| yield from_raw(item) }
        else
          Enumerator.new do |y|
            raw.each { |item| y.yield from_raw(item) }
          end
        end
      end

      protected

      def to_raw(item)
        type.item_type ? type.item_type.to_raw(item)   : item
      end

      def from_raw(item)
        type.item_type ? type.item_type.from_raw(item) : item
      end
    end
  end
end
