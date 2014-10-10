require 'moduler/type'
require 'moduler/base/mix/type_type'

module Moduler
  class Type
    class TypeType < Type
      include Moduler::Base::Mix::TypeType

      def base_type
        Type.empty
      end
      def hash_type
        HashType.empty
      end
      def type_type
        TypeType.empty
      end
      def array_type
        ArrayType.empty
      end
      def set_type
        SetType.empty
      end
      def struct_type
        StructType.empty
      end
    end
  end
end
