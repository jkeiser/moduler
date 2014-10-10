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

        #
        # Handle singular form:
        # address :home, :street => ... do ... end
        # zipcode :home, 80917
        # zipcode :home => 80917, :work => 80918
        #
        def emit_attribute(target, name)
          super
          if @hash[:singular]
            target.send(:define_method, @hash[:singular]) do |*args, &block|
              if args.size == 0
                raise ArgumentError, "#{singular} requires at least one argument: #{singular} <key>, <value> or #{singular} <key> => <value>, <key> => <value> ..."
              end

              # The plural value
              if args[0].is_a?(Hash) && args.size == 1 && !block
                # If we get a hash, we merge in the values
                if args[0].size > 0
                  @hash[name] ||= {}
                  attribute_value = @hash[name]
                  args[0].each do |key,value|
                    key = type.coerce_key(key)
                    value = type.coerce_value(value)
                    attribute_value[key] = value
                    value_type.fire_on_set_raw(value) if value_type
                  end
                end
              else
                # If we get :key, ... do ... end, we do the standard get/set with it.
                key = type.coerce_key(args.shift)
                context = HashValueContext.new(@hash, name, key)
                if value_type
                  value_type.call(context, *args, &block)
                else
                  # Call the empty type
                  self.class.type_type.base_type.call(context, *args, &block)
                end
              end
            end
          end
        end

        class HashValueContext
          def initialize(attributes, name, key)
            @attributes = attributes
            @name = name
            @key  = key
          end

          def get
            if @attributes[@name] && @attributes[@name].has_key?(@key)
              @attributes[@name][@key]
            else
              NO_VALUE
            end
          end

          def set(value)
            @attributes[@name] ||= {}
            @attributes[@name][@key] = value
          end
        end
      end
    end
  end
end
