require 'moduler/type'
require 'moduler/base/mix/type_type'

module Moduler
  class Type
    class TypeType < Type
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

      def specialize_from
        Type.new
      end
      def reopen_on_call
        true
      end

      include Moduler::Base::Mix::TypeType

      attribute :specialize_from do
        default self.class.type_type.base_type
        validator Validation::Validator::KindOf.new(Type)
      end
      attribute :reopen_on_call do
        default true
        validator Validation::Validator::EqualTo.new(true, false)
      end
    end
  end
end
