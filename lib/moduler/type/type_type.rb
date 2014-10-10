require 'moduler/type'
require 'moduler/base/specializable_type'
require 'set'

module Moduler
  class Type
    class TypeType < Type
      include Moduler::Base::SpecializableType

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
        when Moduler::Type
          type

        when ::Array
          if type.size == 0
            Moduler::Type::ArrayType.empty
          elsif type.size == 1
            Moduler::Type::ArrayType.new(element_type: coerce(type[0]))
          end

        when ::Hash
          if type.size == 0
            Moduler::Type::HashType.empty
          elsif type.size == 1
            key_type = coerce?(type.first[0])
            if key_type
              value_type = coerce?(type.first[1])
              if value_type
                Moduler::Type::HashType.new(key_type: key_type, value_type: value_type)
              end
            end
          end

        when ::Set
          if type.size == 0
            Moduler::Type::SetType.empty
          elsif type.size == 1
            Moduler::Type::SetType.new(item_type: coerce(type[0].key))
          end

        when Module
          if type == Array
            Moduler::Type::ArrayType.empty
          elsif type == Hash
            Moduler::Type::HashType.empty
          elsif type == Set
            Moduler::Type::SetType.empty
          elsif type == Moduler::Type
            type = self.class.type_type
          elsif type < Moduler::Type
            type = self.class.type_type.specialize(start_with: type, kind_of: type)
          else
            Moduler::Type.new(kind_of: type)
          end
        end
      end

      def start_with
        Type.empty
      end
      def reopen_on_call
        true
      end

      def start_construction_from?(value)
        coerce?(value)
      end
    end
  end
end
