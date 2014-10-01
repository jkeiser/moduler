require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps a hash interface on top of the raw value (which subclasses can
    # override).
    #
    module HashFacade
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
        key = key_in(key)
        if raw.has_key?(key)
          value_out(key, raw.delete(key))
        end
      end
      def each(&block)
        raw.each do |key, value|
          yield key_out(key), value_out(key, value)
        end
      end
      alias :each_pair :each

      def has_key?(key)
        item_access(key).has_raw?
      end
      def each_key(&block)
        raw.each_key { |key| yield key_out(key) }
      end
      def keys
        each_key.to_a
      end
      def each_value(&block)
        raw.each_value { |value| yield value_out(key, value) }
      end
      def values
        each_value.to_a
      end

      module DSL
        def define_hash_facade(name, key_guard, value_guard)
          new_class(name) do |moduler|
            item_access = moduler.define_hash_item_access(:ItemAccess, key_guard, value_guard)

            include HashFacade
            define_method(:item_access) { |key| item_access.new(self, key_in(key)) }
            define_method(:key_in)      { |key| key_guard.coerce(key) }
            define_method(:key_out)     { |key| key_guard.coerce_out(key) }
            define_method(:value_in)    { |key, value| value_guard.coerce(value) }
            define_method(:value_out)   { |key, value| value_guard.coerce_out(value) }
          end
        end
      end
    end
  end
end
