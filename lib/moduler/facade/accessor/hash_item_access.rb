require 'moduler/facade/guard'

module Moduler
  module Facade
    module Accessor
      #
      # Represents a hash item access (hash[key]).  The access is not resolved
      # until the point of get/set.
      #
      module HashItemAccess
        include Accessor
        
        def initialize(hash, key)
          @hash = hash
          @key = key
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
          def define_hash_item_access(name, value_guard)
            new_class(name, value_guard) { include HashItemAccess }.target
          end
        end
      end
    end
  end
end
