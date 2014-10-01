require 'moduler/guard'

module Moduler
  module Facade
    #
    # Represents a hash item access (hash[key]).  The access is not resolved
    # until the point of get/set.
    #
    module HashItemAccess
      def initialize(hash, key)
        @hash = hash
        @key = key_guard ? key_guard.coerce(key) : key
      end

      def raw
        @hash[@key]
      end
      def raw=(value)
        @hash[@key] = value
      end
      def set?
        @hash.has_key?(@key)
      end

      module DSL
        def define_hash_item_access(name, key_guard, value_guard)
          new_class(name) do
            include Guard.include_guards(value_guard)
            include HashItemAccess
            define_method(:key_guard) { key_guard }
          end
        end
      end
    end
  end
end
