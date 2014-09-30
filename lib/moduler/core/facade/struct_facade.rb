require 'facade'

module Moduler
  module Core
    module Facade
      #
      # Creates a stuct interface on top of the raw value
      #
      module StructFacade
        include Facade
      end

      #
      # Represents an instance variable access (obj.@name).  The access is not resolved
      # until the point of get/set.
      #
      class InstanceVariableAccess
        include Facade
        def initialize(instance, name)
          @instance = instance
          @name = "@#{name}".to_sym
        end

        def raw
          @instance.instance_variable_get(@name)
        end
        def raw=(value)
          @instance.instance_variable_set(@name, value)
        end
        def set?
          @instance.instance_variable_defined?(@name, value)
        end
      end

      def self.define_struct_facade(moduler, name, field_facades)
        moduler.define_module(name) do |moduler|
          include StructFacade
          field_facades.each do |name, facade|
            if facade
              define_method(name) { |*args, &block| facade.call }
              define_method("#{name}=") { |value| facade.set(value) }
            else
              instance_eval <<-EOM
                def #{name}(value=NOT_PASSED, &block)
                  if value == NOT_PASSED
                    if block
                      #{name} = block
                    else
                      @#{name}
                    end
                  elsif block
                    raise "Both value and block passed to attribute!  Only one at a time accepted."
                  else
                    #{name} = value
                  end
                end
                def #{name}=(value)
                  @#{name} = value
                end
              EOM
            end

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

      def self.define_hash_item_access(moduler, name, key_facade, value_facade)
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
