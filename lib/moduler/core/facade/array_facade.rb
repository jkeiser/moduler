require 'facade'

module Moduler
  module Core
    module Facade
      #
      # Slaps an array interface on top of the raw value (which subclasses can
      # override).
      #
      module ArrayFacade
        include Facade
        include Enumerable
        moduler.inline do
          forward :raw, :size
          forward :raw, :[], :[]=, :delete
          forward :raw, :each
        end
      end

      class ArrayItemAccess
        include Facade
        def initialize(array, index)
          @array = array
          @index = index
        end

        def raw
          @array[@index]
        end
        def raw=(value)
          @array[@index] = value
        end
        def set?
          @index < @array.size && @index >= -@array.size
        end
      end

      def self.define_array_facade(moduler, name, index_facade = nil, element_facade = nil)
        moduler.define_module(name) do |moduler|
          include ArrayFacade

          if index_facade || value_facade
            item_access = moduler.facades.define_array_item_access(moduler, :ItemAccess, index_facade, element_facade)

            def [](index)
              item_access.new(array, index).get
            end
            def []=(index, value)
              item_access.new(array, index).set(value) }
            end

            def delete_at(index)
              index = index_facade.coerce_out(index) if index_facade
              if index < raw.size && index >= -array.size
                value = raw.delete_at(index)
                self.class.coerce_out(value)
              end
            end
            def each
              raw.each do |value, index|
                index = index_facade.coerce_out(index) if index_facade
                value = value_facade.coerce_out(value) if value_facade
                yield value, index
              end
            end
            def each_with_index
              raw.each_with_index do |value, index|
                index = index_facade.coerce_out(index) if index_facade
                value = value_facade.coerce_out(value) if value_facade
                yield value, index
              end
            end
            alias :each_pair, :each
          end
        end
      end

      def self.define_array_item_access(moduler, name, index_facade, value_facade)
        moduler.define_class(name, ArrayItemAccess) do
          if index_facade
            def initialize(array, item)
              super(array, index_facade.coerce(index))
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
