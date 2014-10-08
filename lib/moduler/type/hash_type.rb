require 'moduler/type'
require 'moduler/facade/hash_facade'

module Moduler
  class Type
    class HashType < Type
      attr_accessor :key_type
      attr_accessor :value_type

      def facade_class
        Moduler::Facade::HashFacade
      end

      def new_facade(value)
        facade_class.new(coerce(value), self)
      end

      def restore_facade(raw_value)
        facade_class.new(raw_value, self)
      end

      #
      # We store hashes internally as hashes, and slap facades on them when the
      # user requests them.
      #
      def coerce(hash)
        if hash.is_a?(facade_class)
          hash = hash.raw
        elsif key_type || value_type
          hash = hash.inject({}) do |result,(key,value)|
            result[key_type.coerce(key)] = value_type.coerce(value)
            result
          end
        else
          hash = hash.to_hash
        end
        super(hash)
      end

      #
      # When the user requests a hash, we give them a facade (assuming there is
      # a key or value type on this thing).
      #
      def coerce_out(hash)
        if key_type || value_type
          facade_class.new(super, self)
        else
          super
        end
      end

      def coerce_key(key)
        key_type ? key_type.coerce(key) : key
      end

      def coerce_value(raw_key, value)
        value_type ? value_type.coerce(value) : value
      end

      def coerce_keys_out?
        key_type && key_type.coercers_out
      end

      def coerce_values_out?
        !!value_type # Defaults and lazy values come into play :/
      end

      def coerce_key_out(key)
        key_type ? key_type.coerce_out(key) : key
      end

      def coerce_value_out(raw_key, value)
        result = value_type ? value_type.coerce_out(value) : value
        result == NO_VALUE ? nil : result
      end

      def item_type_for(raw_key)
        value_type
      end

      def self.possible_events
        super.merge(:on_hash_updated => Event)
      end
    end
  end
end
