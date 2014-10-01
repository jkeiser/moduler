require 'moduler/guard'

module Moduler
  module Facade
    module ArrayItemAccess
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
          new_class(name) do |moduler|
            moduler.include_guards(value_guard)
            include ArrayItemAccess
            define_method(:index_guard) { index_guard }
          end
        end
      end
    end
  end
end
