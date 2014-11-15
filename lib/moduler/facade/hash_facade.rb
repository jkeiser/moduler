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
          raw_read.inject({}) do |result,(key,value)|
            result[key_from_raw(key)] = from_raw(value)
            result
          end
        else
          # TODO should this be raw?
          raw_read
        end
      end
      def size
        raw_read.size
      end
      def [](key)
        key = key_to_raw(key)
        if raw_read.has_key?(key)
          from_raw(raw_read[key])
        end
      end
      def []=(key, value)
        key = key_to_raw(key)
        result = to_raw(value)
        raw[key] = result
        from_raw(result)
      end
      def delete(key)
        key = key_to_raw(key)
        if raw.has_key?(key)
          from_raw(raw.delete(key))
        end
      end
      def merge(other)
        if other.respond_to?(:type) && other.type == type
          raw_read.merge(other.raw_read(context))
        else
          raw_read.merge(other.to_hash.map { |k,v| [ key_from_raw(k), from_raw(v) ] })
        end
      end
      def merge!(other)
        if other.respond_to?(:type) && other.type == type
          raw.merge!(other.raw_read(context))
        else
          raw.merge!(Hash[other.to_hash.map { |k,v| [ key_to_raw(k), to_raw(v) ] }])
        end
        self
      end

      def each
        if block_given?
          raw_read.each do |key, value|
            yield key_from_raw(key), from_raw(value)
          end
        else
          Enumerator.new do |y|
            raw_read.each do |key, value|
              y.yield key_from_raw(key), from_raw(value)
            end
          end
        end
      end
      alias :each_pair :each

      def has_key?(key)
        raw_read.has_key?(key_to_raw(key))
      end
      def each_key
        if block_given?
          raw_read.each_key { |key| yield key_from_raw(key) }
        else
          Enumerator.new { |y| raw_read.each_key { |key| y << key_from_raw(key) } }
        end
      end
      def keys
        type.key_type ? each_key.to_a : raw_read.keys
      end
      def each_value
        if block_given?
          raw_read.each_value { |value| yield from_raw(value) }
        else
          Enumerator.new { |y| raw_read.each_value { |value| y << from_raw(value) } }
        end
      end
      def values
        type.value_type ? each_value.to_a : raw_read.values
      end

      protected

      def key_to_raw(key)
        type.key_type ? type.key_type.to_raw(key, context) : key
      end

      def key_from_raw(key)
        result = type.key_type ? type.key_type.from_raw(key, context) : key
        child_value(result)
      end

      def to_raw(value)
        type.value_type ? type.value_type.to_raw(value, context) : value
      end

      def from_raw(value)
        result = type.value_type ? type.value_type.from_raw(value, context) : value
        child_value(result)
      end
    end
  end
end
