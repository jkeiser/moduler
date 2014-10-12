require 'moduler/base/type'
require 'moduler/base/array_type'
require 'moduler/base/hash_type'
require 'moduler/base/set_type'
require 'moduler/base/struct_type'
require 'moduler/base/type_type'
require 'moduler/emitter'

module Moduler
  module Base
    module TypeSystem
      def create_local_types
        instance_eval <<-EOM
          # Round 1: create the types and link them up in a type system
          class self::Type
            include Moduler::Base::Type
          end
          class self::StructType < self::Type
            include Moduler::Base::StructType
          end
          class self::TypeType < self::StructType
            include Moduler::Base::TypeType
          end
          class self::HashType < self::Type
            include Moduler::Base::HashType
          end
          class self::ArrayType < self::Type
            include Moduler::Base::ArrayType
          end
          class self::SetType < self::Type
            include Moduler::Base::SetType
          end
        EOM

        # Link the base type back to its parent (the type system)
        local_type_system = self
        self::Type.send(:define_method, :type_system)           { local_type_system }
        self::Type.send(:define_singleton_method, :type_system) { local_type_system }
      end

      def base_type
        @base_type ||= self::Type.new
      end
      def hash_type
        @hash_type ||= self::HashType.new
      end
      def type_type
        @type_type ||= self::TypeType.new
      end
      def array_type
        @array_type ||= self::ArrayType.new
      end
      def set_type
        @set_type ||= self::SetType.new
      end
      def struct_type
        @struct_type ||= self::StructType.new
      end

      def possible_events
        {
          :on_set => Moduler::Event
        }
      end

      def type(*args, &block)
        type_type.call(Moduler::Base::ValueContext.new, *args, &block)
      end

      #
      # DSL construction methods
      #

      def inline(*args, &block)
        # Determine the target from the caller
        target = block.binding.eval('self')

        # See if the target class already has a type; reuse it if so
        if target.respond_to?(:type)
          type = target.type
          type.dsl_eval(*args, &block)
        else
          type = struct_type.specialize(*args, &block)
        end

        # Write it out!
        Moduler::Emitter.emit(type, target)
      end

      def struct(name, *args, &block)
        # Determine the parent from the caller
        parent = block.binding.eval('self')
        if !parent.is_a?(Module)
          parent = parent.class
        end

        # See if the class already exists and reuse it if so
        target = parent.const_get(name, false)
        if target
          if target.respond_to?(:type)
            type = target.type
            type.dsl_eval(*args, &block)
          end
        else
          target = { parent: parent, name: name }
        end

        # Write it out!
        type ||= type(*args, &block)
        Moduler::Emitter.emit(type, target)
      end
    end
  end
end
