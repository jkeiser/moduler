require 'moduler/base/specializable_type'
require 'set'
require 'moduler/base/boolean'
require 'moduler/base/nullable'
require 'moduler/validation/validator/equal_to'
require 'moduler/validation/validator/kind_of'

module Moduler
  module Base
    module TypeType
      include Moduler::Base::SpecializableType

      def base_type
        type_system.base_type
      end
      def array_type
        type_system.array_type
      end
      def hash_type
        type_system.hash_type
      end
      def set_type
        type_system.set_type
      end
      def struct_type
        type_system.struct_type
      end

      #
      # Given a type like Array[String] or Hash[String => Symbol] or ArrayType,
      # resolve it to a system type.
      #
      def coerce(type)
        type = super
        if !type.is_a?(LazyValue)
          coerced = coerce?(type)
          if coerced
            type = coerced
          else
            raise "Unrecognized type #{type}"
          end
        end
        type
      end

      def coerce?(type)
        case type
        when base_type.class
          type

        when ::Array
          if type.size == 0
            array_type
          elsif type.size == 1
            array_type.specialize(element_type: coerce(type[0]))
          end

        when ::Hash
          if type.size == 0
            hash_type
          elsif type.size == 1
            key_type = coerce?(type.first[0])
            if key_type
              value_type = coerce?(type.first[1])
              if value_type
                hash_type.specialize(key_type: key_type, value_type: value_type)
              end
            end
          end

        when ::Set
          if type.size == 0
            set_type
          elsif type.size == 1
            set_type.specialize(item_type: coerce(type[0].key))
          end

        when Nullable
          # Honestly, the Right Thing is compound types with unions, but we
          # don't support them and I'm not ready to force them until we need
          # them badly--too much conceptual overhead.
          coerce(type.type).specialize skip_coercion_if: nil

        when Module
          if type == Array
            array_type
          elsif type == Hash
            hash_type
          elsif type == Set
            set_type
          elsif type == Nullable
            base_type.specialize skip_coercion_if: nil
          elsif type == Boolean
            base_type.specialize do
              add_validator Validation::Validator::EqualTo.new(true, false)
            end
          elsif type == base_type.class
            type_system.type_type
          elsif type < base_type.class
            type_system.type_type.specialize do
              specialize_from type.empty
              add_validator Validation::Validator::KindOf.new(type)
            end
          else
            base_type.specialize do
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
