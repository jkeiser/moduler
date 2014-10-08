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
        value_type ? value_type.coerce(value) : value
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
