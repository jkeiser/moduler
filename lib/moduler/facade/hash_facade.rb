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
        if !hash
          raise "omg"
        end
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
        if type.coerce_keys_out? || type.coerce_values_out?
          # TODO don't coerce unless it's dirty
          hash.inject({}) do |result,(key,value)|
            result[type.coerce_key_out(key)] = type.coerce_value_out(key, value)
            result
          end
        else
          hash
        end
      end
      def size
        hash.size
      end
      def [](key)
        key = type.coerce_key(key)
        if hash.has_key?(key)
          type.coerce_value_out(key, hash[key])
        end
      end
      def []=(key, value)
        key = type.coerce_key(key)
        result = type.coerce_value(key, value)
        hash[key] = result
        type.coerce_value_out(key, result)
      end
      def delete(key)
        key = type.coerce_key(key)
        if hash.has_key?(key)
          type.coerce_value_out(key, hash.delete(key))
        end
      end
      def each
        if type.coerce_keys_out? || type.coerce_values_out?
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
        else
          hash.each
        end
      end
      alias :each_pair :each

      def has_key?(key)
        key = type.coerce_key(key)
        hash.has_key?(key)
      end
      def each_key
        if type.coerce_keys_out?
          if block_given?
            hash.each_key { |key| yield type.coerce_key_out(key) }
          else
            Enumerator.new { |y| hash.each_key { |key| y << type.coerce_key_out(key) } }
          end
        else
          hash.each_key
        end
      end
      def keys
        type.coerce_keys_out? ? each_key.to_a : hash.keys
      end
      def each_value
        if type.coerce_values_out?
          if block_given?
            hash.each_value { |value| yield type.coerce_value_out(nil, value) }
          else
            Enumerator.new { |y| hash.each_value { |value| y << type.coerce_value_out(nil, value) } }
          end
        else
          hash.each_value
        end
      end
      def values
        if type.coerce_values_out?
          each_value.to_a
        else
          hash.values
        end
      end
    end
  end
end
