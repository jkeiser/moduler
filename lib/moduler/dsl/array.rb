require 'moduler/base/module_dsl'
require 'moduler/array_facade'

module Moduler
  module Base
    module Array
      include Moduler::Base::ModuleDSL

      def initialize(parent, name, *args, &block)
        # TODO don't make or use a facade class unless we have validation going on
        moduler = Modulemoduler.create(parent, name, Class, ArrayFacade)
        super(moduler, *args, &block)
      end

      def element_dsl=(value)
        @element_dsl = value
        expressions = @element_dsl.get_expressions {
          set: "",
          set_var: "item",
          get: "item",
        }
        module_moduler.add_dsl_method(:value_for_set, expressions[:set], 'item')
        module_moduler.add_dsl_method(:value_for_get, expressions[:get], 'item')
      end

      def element_dsl
        @element_dsl
      end

      def get_expression(expressions)
        module_name = module_moduler.target.name
        expressions[:set] = <<-EOM
          if !#{set_var}.is_a?(#{module_name})
            #{set_var} = #{module_name}.new(#{set_var})
          end
          #{expressions[set]}
        EOM
        super(expressions)
      end

      class ArrayFacade
        include Enumerable

        # TODO delete, |, and value-based find/deletion will work funny with lazy
        # values.  Fix that (value_for_get is not the solution!  Need to just
        # de-lazify)

        # TODO add SetType and SetFacade, because sets are rad.

        def initialize(items)
          @items = items
        end

        def each
          items.each do |item|
            yield value_for_get(item)
          end
        end

        def [](index)
          value_for_get(items[index])
        end

        def []=(index, item)
          items[index] = value_for_set(item)
        end

        def size
          items.size
        end

        # TODO :splice, +, |, ...

        def delete(item)
          items.delete(value_for_set(item))
        end

        def <<(item)
          items << value_for_set(item)
        end

        def add(item)
          items.add(value_for_set(item))
        end
      end
    end
  end
end
