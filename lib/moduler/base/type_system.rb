require 'moduler'
require 'moduler/base/attribute'
require 'moduler/base/mix/type'
require 'moduler/base/mix/array_type'
require 'moduler/base/mix/hash_type'
require 'moduler/base/mix/set_type'
require 'moduler/base/mix/struct_type'
require 'moduler/base/mix/type_type'

module Moduler
  module Base
    class TypeSystem
      def initialize(base_module)
        @base_module = base_module
      end

      def base_type
        @base_type ||= @base_module::Type.new
      end
      def hash_type
        @hash_type ||= @base_module::HashType.new
      end
      def type_type
        @type_type ||= @base_module::TypeType.new
      end
      def array_type
        @array_type ||= @base_module::ArrayType.new
      end
      def set_type
        @set_type ||= @base_module::SetType.new
      end
      def struct_type
        @struct_type ||= @base_module::StructType.new
      end

      def possible_events
        {
          :on_set => Event
        }
      end

      def emit_attribute(target, name, *args, &block)
        if args.size > 0 || block
          type = type(*args, &block)
          if !type
            Attribute.emit_attribute(target, name)
          else
            type.emit_attribute(target, name)
          end
        else
          Attribute.emit_attribute(target, name)
        end
      end

      def attribute(name, *args, &block)
        emit_attribute(self, name, *args, &block)
      end

      def type(*args, &block)
        type_type.call(Moduler::Base::ValueContext.new, *args, &block)
      end
    end
  end
end
