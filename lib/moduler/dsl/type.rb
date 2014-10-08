module Moduler
  module DSL
    # class methods:
      # inline
      # struct
      # struct_module
      # facade

    class Base
      protected

      def to_base_type(type)
        case type
        when Moduler::Type
          type

        when ::Array
          if type.size == 0
            Moduler::ArrayType.new
          elsif type.size == 1
            Moduler::ArrayType.new(element_type => to_type(type[0]))
          end

        when ::Hash
          if type.size == 0
            Moduler::HashType.new
          elsif type.size == 1
            Moduler::HashType.new(key_type   => to_type(type[0].key),
                                  value_type => to_type(type[0].value))
          end
        end
      end

      def to_type(base=NOT_PASSED, *args, &block)
        if base == NOT_PASSED
          type = Moduler::Type.new
        else
          type = to_base_type(base)
          if !type
            args.unshift(base)
            type = Moduler::Type.new
          end
        end

        if args.size > 0 || block
          type.specialize(*args, &block)
        else
          type
        end
      end

      # type :name, OtherType,   :a => b, :c => d do ... end
      # type :name => OtherType, :a => b, :c => d do ... end
      # type OtherType,          :a => b, :c => d do ... end
      # type :name,              :a => b, :c => d do ... end
      # type                     :a => b, :c => d do ... end
    end

    class Type < Base
      # default_value
      def default_value(*args, &block)
        
      end
      # required
      # coercions
      # validation attributes
      # on_set
    end

    class ArrayType < Type
      # index_type
      # element_type
      # singular
      # on_array_updated
    end

    class HashType < Type
      # key_type
      # value_type
      # on_hash_updated
    end

    class SetType < Type
      # item_type
      # singular
      # on_set_updated
    end

    class StructType < Type
      # includes
      # attributes
      # reopen_on_call
    end

    class StructHashType < StructType
      # key_type
      # value_type
      # is_open
      # on_hash_updated
    end

    class TypeType < StructType
    end
  end
end
