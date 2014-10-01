require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps an array interface on top of the raw value (which subclasses can
    # override).
    #
    # Assumes the existence of `raw`, `item_facade`, `index_guard` and `element_guard`.
    #
    module ArrayFacade
      include Enumerable

      def size
        raw.size
      end
      def [](index)
        item_access(index).get
      end
      def []=(index, value)
        access = item_access(index)
        result = access.set(value)
        access.call_if(:on_set, result)
        result
      end
      def delete_at(index)
        index = index_in(index)
        if index < raw.size && index >= -raw.size
          value_out(raw.delete_at(index))
        end
      end
      def each
        raw.each do |value|
          yield value_out(value)
        end
      end
      def each_with_index
        raw.each_with_index do |value, index|
          yield value_out(value), index_out(index)
        end
      end
      alias :each_pair :each

      module DSL
        def define_array_facade(name, index_guard, item_guard)
          new_class(name) do |moduler|
            item_access = moduler.define_array_item_access(:ItemAccess, index_guard, item_guard)

            include ArrayFacade

            define_method(:item_access) { |index| item_access.new(self, index_in(index))}
            define_method(:index_in)    { |index| index_guard.coerce(index) }
            define_method(:index_out)   { |index| index_guard.coerce_out(index) }
            define_method(:value_in)    { |value| item_guard.coerce(value) }
            define_method(:value_out)   { |value| item_guard.coerce_out(value) }
          end
        end
      end
    end
  end
end
