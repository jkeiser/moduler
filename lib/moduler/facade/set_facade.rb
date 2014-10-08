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

      def initialize(set, type)
        @set = set
        @type = type
      end

      attr_reader :set
      attr_reader :type

      def ==(other)
        if other.is_a?(Set) || other.is_a?(SetFacade)
          to_set == other.to_set
        else
          false
        end
      end
      def to_set
        Set.new(each)
      end
      def size
        set.size
      end
      def to_a
        set.map { |item| type.coerce_item_out(item) }
      end
      def include?(item)
        set.include?(type.coerce_item(item))
      end
      def member?(item)
        set.member?(type.coerce_item(item))
      end
      def add(item)
        set.add(type.coerce_item(item))
        self
      end
      def add?(item)
        set.add?(type.coerce_item(item)) ? self : nil
      end
      def <<(item)
        set << type.coerce_item(item)
        self
      end
      def delete(item)
        set.delete(type.coerce_item(item))
        self
      end
      def each
        if block_given?
          set.each { |item| yield type.coerce_item_out(item) }
        else
          Enumerator.new do |y|
            set.each { |item| y.yield type.coerce_item_out(item) }
          end
        end
      end
    end
  end
end
