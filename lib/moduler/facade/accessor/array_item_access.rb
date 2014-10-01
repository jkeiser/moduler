require 'moduler/facade/guard'

module Moduler
  module Facade
    module Accessor
      module ArrayItemAccess
        include Accessor
        
        def initialize(array, index)
          @array = array
          @index = index_guard ? index_guard.coerce(index) : index
        end

        attr_reader :array
        attr_reader :index

        def raw
          array[]
        end
        def raw=(index)
          array[index_guard.coerce(index)]
        end
        def has_raw?(index)
          index >= -array.size && index < array.size
        end

        module DSL
          def define_array_item_access(name, index_guard, value_guard)
            new_class(name, value_guard) do |moduler|
              include ArrayItemAccess
              define_method(:index_guard) { index_guard }.target
            end
          end
        end
      end
    end
  end
end
