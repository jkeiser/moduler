require 'moduler/facade/value_facade'

module Moduler
  module Facade
    #
    # Slaps a hash interface on top of the hash value (which subclasses can
    # override).
    #
    class HashFacade < ValueFacade
      include Enumerable

      def ==(other)
        if other.is_a?(Hash) || other.is_a?(HashFacade)
          to_hash == other.to_hash
        else
          false
        end
      end
      def to_hash
        if type.key_type || type.value_type
          # TODO don't coerce unless it's dirty
          raw.inject({}) do |result,(key,value)|
            result[key_from_raw(key)] = from_raw(value)
            result
          end
        else
          # TODO should this be raw_write?
          raw
        end
      end
      def size
        raw.size
      end
      def [](key)
        key = key_to_raw(key)
        if raw.has_key?(key)
          from_raw(raw[key])
        end
      end
      def []=(key, value)
        key = key_to_raw(key)
        result = to_raw(value)
        raw_write[key] = result
        from_raw(result)
      end
      def delete(key)
        key = key_to_raw(key)
        if raw_write.has_key?(key)
          from_raw(raw_write.delete(key))
        end
      end
      def merge(other)
        if other.respond_to?(:type) && other.type == type
          raw.merge(other.raw)
        else
          raw.merge(other.to_hash.map { |k,v| [ key_from_raw(k), from_raw(v) ] })
        end
      end
      def merge!(other)
        if other.respond_to?(:type) && other.type == type
          raw_write.merge!(other.raw)
        else
          raw_write.merge!(Hash[other.to_hash.map { |k,v| [ key_to_raw(k), to_raw(v) ] }])
        end
        self
      end

      def each
        if block_given?
          raw.each do |key, value|
            yield key_from_raw(key), from_raw(value)
          end
        else
          Enumerator.new do |y|
            raw.each do |key, value|
              y.yield key_from_raw(key), from_raw(value)
            end
          end
        end
      end
      alias :each_pair :each

      def has_key?(key)
        raw.has_key?(key_to_raw(key))
      end
      def each_key
        if block_given?
          raw.each_key { |key| yield key_from_raw(key) }
        else
          Enumerator.new { |y| raw.each_key { |key| y << key_from_raw(key) } }
        end
      end
      def keys
        type.key_type ? each_key.to_a : raw.keys
      end
      def each_value
        if block_given?
          raw.each_value { |value| yield from_raw(value) }
        else
          Enumerator.new { |y| raw.each_value { |value| y << from_raw(value) } }
        end
      end
      def values
        type.value_type ? each_value.to_a : raw.values
      end

      protected

      def key_to_raw(key)
        type.key_type ? type.key_type.to_raw(key) : key
      end

      def key_from_raw(key)
        type.key_type ? type.key_type.from_raw(key) : key
      end

      def to_raw(value)
        type.value_type ? type.value_type.to_raw(value) : value
      end

      def from_raw(value)
        type.value_type ? type.value_type.from_raw(value) : value
      end
    end
  end
end
