module Moduler
  module DSL
    # class methods:
      # inline
      # struct
      # struct_module
      # facade

    class Base
      # type
    end

    class Type < Base
      # default_value
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
