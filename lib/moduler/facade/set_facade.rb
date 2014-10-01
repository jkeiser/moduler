require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps an array interface on top of the raw value (which subclasses can
    # override).
    #
    # Assumes the existence of raw and item_guard.
    #
    module SetFacade
      include Facade
      include Enumerable

      def include?(item)
        item = item_guard.coerce(item) if item_guard
        raw.include?(item)
      end
      def member?(item)
        item = item_guard.coerce(item) if item_guard
        raw.member?(item)
      end
      def add(item)
        item = item_guard.coerce(item) if item_guard
        raw.add(item)
      end
      def <<(item)
        item = item_guard.coerce(item) if item_guard
        raw << item
      end
      def delete(item)
        item = item_guard.coerce(item) if item_guard
        raw.delete(item)
      end
      def each(&block)
        if item_guard
          raw.each { |item| yield item_guard.coerce(item) }
        else
          raw.each(&block)
        end
      end

      module DSL
        def define_set_facade(name, item_guard)
          new_module(name) do |moduler|
            include SetFacade
            define_method(:item_guard) { item_guard }
          end
        end
      end
    end
  end
end
