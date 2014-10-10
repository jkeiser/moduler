require 'moduler/base/specializable_type'
require 'set'

module Moduler
  module Base
    module Mix
      module TypeType
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

          when Module
            if type == Array
              array_type
            elsif type == Hash
              hash_type
            elsif type == Set
              set_type
            elsif type == base_type.class
              type = type_type
            elsif type < base_type.class
              # TODO bring kind_of back when basic validation is supported--perhaps with direct instantiation
              type_type#.specialize(start_with: type, kind_of: type)
            else
              base_type#.specialize(kind_of: type)
            end
          end
        end
        def start_with
          base_type
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
end
