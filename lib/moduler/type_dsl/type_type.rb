require 'moduler/type_dsl'
require 'moduler/base/nullable'
require 'moduler/base/boolean'

module Moduler
  module TypeDSL
    #
    #
    # Given a type like Array[String] or Hash[String => Symbol] or ArrayType,
    # resolve it to a system type.
    #
    class TypeType < StructType
      def coerce(type)
        if !type.is_a?(LazyValue)
          coerced = coerce?(type)
          if coerced
            type = coerced
          else
            raise "Unrecognized type #{type}"
          end
        end
        super(type)
      end

      def coerce?(type)
        case type
        when Base::Type
          type

        when ::Array
          if type.size == 0
            ArrayType.new
          elsif type.size == 1
            ArrayType.new(element_type: coerce(type[0]))
          end

        when ::Hash
          if type.size == 0
            HashType.new
          elsif type.size == 1
            key_type = coerce?(type.first[0])
            if key_type
              value_type = coerce?(type.first[1])
              if value_type
                HashType.new(key_type: key_type, value_type: value_type)
              end
            end
          end

        when ::Set
          if type.size == 0
            SetType.new
          elsif type.size == 1
            SetType.new(item_type: coerce(type[0].key))
          end

        when Base::Nullable
          # Honestly, the Right Thing is compound types with unions, but we
          # don't support them and I'm not ready to force them until we need
          # them badly--too much conceptual overhead.
          coerce(type.type).specialize skip_coercion_if: nil

        when Module
          if type == Array
            ArrayType.new
          elsif type == Hash
            HashType.new
          elsif type == Set
            SetType.new
          elsif type == Base::Nullable
            Type.new skip_coercion_if: nil
          elsif type == Base::Boolean
            Type.new do
              add_validator Validation::Validator::EqualTo.new(true, false)
            end
          elsif type == Type
            TypeType.new
          elsif type < Type
            TypeType.new do
              specialize_from Type.new
              add_validator Validation::Validator::KindOf.new(type)
            end
          else
            TypeType.new do
              add_validator Validation::Validator::KindOf.new(type)
            end
          end
        end
      end

      def specialize_from?(value)
        coerce?(value)
      end
    end
  end
end
