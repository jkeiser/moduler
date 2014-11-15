require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps a set interface on top of the set value (which subclasses can
    # override).
    #
    class SetFacade
      include Facade
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
        raw_read.size
      end
      def to_a
        raw_read.map { |item| from_raw(item) }
      end
      def include?(item)
        raw_read.include?(to_raw(item))
      end
      def member?(item)
        raw_read.member?(to_raw(item))
      end
      def add(item)
        raw.add(to_raw(item))
        self
      end
      def add?(item)
        raw.add?(to_raw(item)) ? self : nil
      end
      def <<(item)
        raw << to_raw(item)
        self
      end
      def delete(item)
        raw.delete(to_raw(item))
        self
      end
      def each
        if block_given?
          raw_read.each { |item| yield from_raw(item) }
        else
          Enumerator.new do |y|
            raw_read.each { |item| y.yield from_raw(item) }
          end
        end
      end

      protected

      def to_raw(item)
        type.item_type ? type.item_type.to_raw(item, context)   : item
      end

      def from_raw(item)
        type.item_type ? type.item_type.from_raw(item, context) : item
      end
    end
  end
end
