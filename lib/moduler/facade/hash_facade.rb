require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps a hash interface on top of the raw value (which subclasses can
    # override).
    #
    module HashFacade
      include Facade
      include Enumerable
      def size
        raw.size
      end
      def [](key)
        item_access(key).get
      end
      def []=(key, value)
        access = item_access(key)
        result = access.set(value)
        access.call_if(:on_set, result)
        result
      end
      def delete(key)
        value_guard = value_guard_for(key)
        key = key_guard.coerce_out(key) if key_guard
        if raw.has_key?(key)
          value = raw.delete(key)
          value = value_guard.coerce_out(value) if value
          value
        end
      end
      def each(&block)
        value_guard = value_guard_for(key)
        if key_guard || value_guard
          raw.each do |key, value|
            key = key_guard.coerce_out(key) if key_guard
            value = value_guard_for(key).coerce_out(value) if value_guard
            yield key, value
          end
        else
          raw.each(&block)
        end
      end
      alias :each_pair :each

      def has_key?(key)
        item_access(key).has_raw?
      end
      def each_key(&block)
        if key_guard
          raw.each_key { |key| yield key_guard.coerce_out(key) }
        else
          raw.each_key(&block)
        end
      end
      def keys
        each_key.to_a
      end
      def each_value(&block)
        if value_guard_for(key)
          raw.each_value { |value| yield value_guard_for(key).coerce_out(value) }
        else
          raw.each_value
        end
      end
      def values
        each_value.to_a
      end

      module DSL
        def define_hash_facade(name, key_guard, value_guard)
          new_module(name) do |moduler|
            item_access = moduler.define_hash_item_access(:ItemAccess, key_guard, element_facade)

            include HashFacade
            define_method(:key_guard)       { key_guard }
            define_method(:item_access)     { |key| item_access }
            define_method(:value_guard_for) { |key| value_guard }
          end
        end
      end
    end
  end
end
