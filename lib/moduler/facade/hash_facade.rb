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

      def ==(other)
        if other.is_a?(Hash) || other.is_a?(HashFacade)
          to_hash == other.to_hash
        else
          false
        end
      end
      def to_hash
        # TODO don't coerce unless it's dirty
        hash.inject({}) do |result,(key,value)|
          result[type.coerce_key_out(key)] = type.coerce_value_out(key, value)
          result
        end
      end
      def size
        hash.size
      end
      def [](key)
        key = type.coerce_key(key)
        type.coerce_value_out(key, hash.has_key?(key) ? hash[key] : NO_VALUE)
      end
      def []=(key, value)
        key = type.coerce_key(key)
        result = type.coerce_value(key, value)
        hash[key] = result
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
      def each
        if block_given?
          hash.each do |key, value|
            yield type.coerce_key_out(key), type.coerce_value_out(key, value)
          end
        else
          Enumerator.new do |y|
            hash.each do |key, value|
              y.yield type.coerce_key_out(key), type.coerce_value_out(key, value)
            end
          end
        end
      end
      alias :each_pair :each

      def has_key?(key)
        key = type.coerce_key(key)
        hash.has_key?(key)
      end
      def each_key
        if block_given?
          hash.each_key { |key| yield type.coerce_key_out(key) }
        else
          Enumerator.new { |y| hash.each_key { |key| y << type.coerce_key_out(key) } }
        end
      end
      def keys
        each_key.to_a
      end
      def each_value
        if block_given?
          hash.each_value { |value| yield type.coerce_value_out(nil, value) }
        else
          Enumerator.new { |y| hash.each_value { |value| y << type.coerce_value_out(nil, value) } }
        end
      end
      def values
        each_value.to_a
      end
    end
  end
end
