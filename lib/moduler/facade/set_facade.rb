require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps a set interface on top of the raw value (which subclasses can
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

      def include?(item)
        raw.include?(type.coerce_item(item))
      end
      def member?(item)
        raw.member?(type.coerce_item(item))
      end
      def add(item)
        raw.add(type.coerce_item(item))
      end
      def <<(item)
        raw << type.coerce_item(item)
      end
      def delete(item)
        raw.delete(type.coerce_item(item))
      end
      def each(&block)
        raw.each { |item| yield type.coerce_item_out(item) }
      end
    end
  end
end
