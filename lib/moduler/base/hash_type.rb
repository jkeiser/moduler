require 'moduler/base/type'
require 'moduler/facade/hash_facade'

module Moduler
  module Base
    class HashType < Type
      def raw_get?
        false
      end

      def clone_value(value)
        if !value
          value
        elsif key_type || value_type
          value.inject({}) do |r,(key,value)|
            key = key_type.clone_value(key) if key_type
            value = value_type.clone_value(value) if value_type
            r[key] = value
            r
          end
        else
          value.dup
        end
      end

      #
      # We store hashes internally as hashes, and slap facades on them when the
      # user requests them.
      #
      def coerce(hash)
        if hash.is_a?(Moduler::Facade::HashFacade)
          hash = hash.hash
        elsif key_type || value_type
          hash = hash.inject({}) do |result,(key,value)|
            key = key_type.coerce(key) if key_type
            value = value_type.coerce(value) if value_type
            result[key] = value
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
      def coerce_out(hash, &cache_proc)
        hash = raw_value(hash, &cache_proc)
        if hash == NO_VALUE
          hash = {}
          cache_proc.call(hash)
        end

        if key_type || value_type
          Moduler::Facade::HashFacade.new(hash, self)
        else
          hash
        end
      end

      def coerce_key(key)
        key_type ? key_type.coerce(key) : key
      end

      def coerce_value(raw_key, value)
        value_type ? value_type.coerce(value) : value
      end

      def coerce_keys_out?
        key_type
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

      def new_facade(hash)
        Facade::HashFacade.new(Hash[hash.map { |key,value| [ coerce_key(key), coerce_value(key, value) ] }], self)
      end
    end
  end
end
