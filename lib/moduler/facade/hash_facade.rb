require 'moduler/facade'

module Moduler
  module Facade
    #
    # Slaps a hash interface on top of the hash value (which subclasses can
    # override).
    #
    class HashFacade
      include Facade
      include Enumerable

      def initialize(hash, type)
        @hash = hash
        @type = type
      end

      attr_reader :hash
      attr_reader :type

      def size
        hash.size
      end
      def [](key)
        key = type.coerce_key(key)
        type.coerce_value(key, hash.has_key?(key) ? hash[key] : NO_VALUE)
      end
      def []=(key, value)
        key = type.coerce_key(key)
        self[key] = result = type.coerce_value(index, value)
        result = type.coerce_value_out(key, result)
        if type.events[:on_set]
          type.events[:on_set].fire(:on_set, result)
        end
        result
      end
      def delete(key)
        key = type.coerce_key(key)
        if hash.has_key?(key)
          type.coerce_value_out(key, hash.delete(key))
        end
      end
      def each(&block)
        hash.each do |key, value|
          yield type.coerce_key_out(key), type.coerce_value_out(key, value)
        end
      end
      alias :each_pair :each

      def has_key?(key)
        item_access(key).has_hash?
      end
      def each_key(&block)
        hash.each_key { |key| yield type.coerce_key_out(key) }
      end
      def keys
        each_key.to_a
      end
      def each_value(&block)
        hash.each_value { |value| yield type.coerce_value_out(key, value) }
      end
      def values
        each_value.to_a
      end
    end
  end
end
