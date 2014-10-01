require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps an array interface on top of the raw value (which subclasses can
    # override).
    #
    # Assumes the existence of raw, item_in(item) and item_out(item).
    #
    module SetFacade
      include Enumerable

      def include?(item)
        raw.include?(item_in(item))
      end
      def member?(item)
        raw.member?(item_in(item))
      end
      def add(item)
        raw.add(item_in(item))
      end
      def <<(item)
        raw << item_in(item)
      end
      def delete(item)
        raw.delete(item_in(item))
      end
      def each(&block)
        raw.each { |item| yield item_in(item) }
      end

      module DSL
        def define_set_facade(name, item_guard)
          new_class(name) do
            include SetFacade
            define_method(:item_in)  { |item| item_guard.coerce(item) }
            define_method(:item_out) { |item| item_guard.coerce_out(item) }
          end
        end
      end
    end
  end
end
