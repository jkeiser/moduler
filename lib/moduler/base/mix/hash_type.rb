require 'moduler/event'
require 'moduler/facade/hash_facade'

module Moduler
  module Base
    module Mix
      module HashType
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
          hash = super
          if hash == NO_VALUE
            hash = {}
            cache_proc.call(hash)
          end

          if key_type || value_type
            facade_class.new(hash, self)
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
          key_type && key_type.coercer_out
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
end
