require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps an array interface on top of the raw value (which subclasses can
    # override).
    #
    # Assumes the existence of `raw`, `item_access`, `index_guard` and `element_guard`.
    #
    module ArrayFacade
      include Enumerable

      def size
        raw.size
      end
      def [](index)
        item_access.new(raw, index).get
      end
      def []=(index, value)
        access = item_access.new(raw, index)
        result = access.set(value)
        access.call_if(:on_set, result)
        result
      end
      def delete_at(index)
        index = index_guard.coerce_out(index) if index_guard
        if index < raw.size && index >= -raw.size
          value = raw.delete_at(index)
          value = value_guard.coerce_out(value) if value_guard
          value
        end
      end
      def each
        raw.each do |value|
          value = value_guard.coerce_out(value) if value_guard
          yield value
        end
      end
      def each_with_index
        raw.each_with_index do |value, index|
          index = index_guard.coerce_out(index) if index_guard
          value = value_guard.coerce_out(value) if value_guard
          yield value, index
        end
      end
      alias :each_pair :each

      module DSL
        def define_array_facade(name, index_guard, element_guard)
          new_module(name) do |moduler|
            item_access = moduler.define_array_item_access(:ItemAccess, index_guard, element_guard)

            include ArrayFacade

            define_method(:item_access)   { item_access }
            define_method(:index_guard)   { index_guard }
            define_method(:element_guard) { element_guard }
          end
        end
      end
    end
  end
end
