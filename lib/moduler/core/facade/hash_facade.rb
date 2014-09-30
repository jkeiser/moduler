module Moduler
  module Core
    module Facade
      #
      # Slaps a hash interface on top of the raw value (which subclasses can
      # override).
      #
      module HashFacade
        include Facade
        Moduler.inline do
          forward :raw, :size
          forward :raw, :[], :[]=, :delete
          forward :raw, :each, :each_pair, :each_key, :each_value, :keys, :values
        end
      end

      #
      # Represents a hash item access (hash[key]).  The access is not resolved
      # until the point of get/set.
      #
      class HashItemAccess
        include Facade
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
      end

      def define_hash_facade(name, key_facade = nil, element_facade = nil)
        moduler.define_module(name) do |moduler|
          include HashFacade

          if key_facade || value_facade
            item_access = moduler.facades.define_hash_item_access(moduler, :ItemAccess, key_facade, element_facade)

            def [](key)
              item_access.new(@hash, key).get
            end
            def []=(key, value)
              item_access.new(@hash, key).set(value)
            end
            def delete(key)
              key = key_facade.coerce_out(key) if key_facade
              if @hash.has_key?(key)
                value = @hash.delete(key)
                self.class.coerce_out(value)
              end
            end
            def each
              @hash.each do |key, value|
                key = key_facade.coerce_out(key) if key_facade
                value = value_facade.coerce_out(value) if value_facade
                yield key, value
              end
            end
            alias :each_pair, :each
          end

          if key_facade
            def has_key?(key)
              item_access.new(@hash, @key)
            end
            def each_key
              @hash.each_key { |key| yield key_facade.coerce_out(key) }
            end
            def keys
              each_key.to_a
            end
          end

          if value_facade
            def each_value
              @hash.each_value { |value| yield key_facade.coerce_out(value) }
            end
            def values
              each_value.to_a
            end
          end
        end
      end

      def define_hash_item_access(moduler, name, key_facade, value_facade)
        moduler.define_class(name, HashItemAccess) do
          if key_facade
            def initialize(hash, key)
              super(@hash, key_facade.coerce(key))
            end
          end

          if value_facade
            include value_facade
          end
        end
      end
    end
  end
end
