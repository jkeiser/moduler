require 'moduler/base/module_dsl'
require 'moduler/array_facade'

module Moduler
  module Base
    module Hash
      include Moduler::Base::ModuleDSL

      def initialize(moduler, name, *args, &block)
        moduler = moduler.create_class(name, HashFacade)
        super(moduler, *args, &block)
      end

      attr_accessor :key_dsl
      attr_accessor :value_dsl

      #
      # Given a key, get the expressions to transform it to/from raw format
      #
      def key_expr(options = nil, &block)
      end

      #
      # Given a value, get the expressions for get/set/etc.
      #
      def value_expr(options = nil, &block)
        if !options && !block
          options = { input: 'key', output: 'key' }
        end
        expr = moduler.value_expressions(options, &block)
        value_dsl ? value_dsl.value_expressions(expr) : expr
      end

      def value_set(&block)
      end

      def key_expr
        moduler.value_expressions { input }
      end

      def value_expr
        value_proc =
        value = moduler.value_expressions { input { value }; output { value } }
        value = value_dsl.value_expressions(value_expr) if value_dsl
        value_expr.blocks
      end

      class HashExpressions
        def initialize(index, expr)
          @index = index
          @expr = expr
        end
        def method_missing(name, *args, &block)
          result = expr.public_send(name, *args, &block)
          result = proc do |key, *args, &block|
            hash[key]result.call(*args, &block) }
          # Bring index into local scope
          index = @index
          result =
        end
        def get
          index = @index
          expr
      end

      module ValuesDSL
        include Moduler::Base::Specializable

        #
        # A Value class represents an instantiable value which can be protected
        # by the type system.  For example:
        #
        # - If a type has validators attached to it, values in set() will run
        #   them before allowing the value to be set.
        # - If a type has defaults, get() will return the default is set? is
        #   false.
        # - If a type has coercions, set() values will be transformed before
        #   being stored, and get() values will be transformed before being
        #   handed back to the user.
        # - If a type has on_call, on_set, on_get, etc., these will be called.
        #
        class Value
          include Transform
          def get
            raise NotImplementedError
          end
          def set(value)
            raise NotImplementedError
          end
          def set?
            raise NotImplementedError
          end
          def call(*args, &block)
            raise NotImplementedError
          end
        end

        class RawValue < Value
          def get
            self
          end
          def set?
            true
          end
        end

        class ArrayItemValue
          def
        end

        #
        # A Transform is a module that presents a "facade" for a value, overriding
        # one or more of the Value methods.  Transforms are meant to be included
        # into a module or class in order from inner to outer (the last one
        # included--the first class in the ancestors list--is the outermost).
        #
        # Transform methods are expected to call super to the inner value.
        #
        module Transform
          # get
          # set(value)
          # set?
          # call
        end

        module StandardTransforms
        end

        class ArrayItemValue
          def initialize

          end
        end

      def on_close
        key = key_type.transformer
        value = key_type.transformer
        index =
        value = value_type.value_expressions
        index = value_type.value_expressions do
          input  { |index| hash[index] }
          output { |index| }
          set { |index, value| hash[index] = }
        end
          get { |index| hash[index] }
        end)
        # Transform the user input key
        index = moduler.value_expressions do
          input { expr[:value] }
          output { hash[key.input.call] }
          set { |value| hash[key.input.call] = value }
          set? { hash.has_key?(key.input.call) }
        )
        value

      end

      class HashFacade
        include Enumerable

        def initialize(hash)
          @hash = hash
        end

        def size
          hash.size
        end

        # TODO merge, ...
      end
    end
  end
end
