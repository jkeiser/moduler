require 'moduler/type'
require 'moduler/facade/hash_facade'
module Moduler
  class Type
    class HashType < Type
      attr_accessor :key_type
      attr_accessor :value_type

      def facade_class
        HashFacade
      end

      def coerce(hash)
        if hash.is_a?(facade_class)
          hash = hash.raw
        end
        super(hash)
      end

      def coerce_out(hash)
        facade_class.new(super, self)
      end

      def coerce_key(key)
        key_type ? key_type.coerce(key) : key
      end

      def coerce_value(raw_key, value)
        field_types[raw_key] ? field_types[raw_key].coerce(value) : value
      end

      def coerce_key_out(key)
        key_type ? key_type.coerce_out(key) : key
      end

      def coerce_value_out(raw_key, value)
        field_types[raw_key] ? field_types[raw_key].coerce_out(value) : value
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
