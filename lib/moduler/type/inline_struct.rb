require 'moduler/base/inline_struct'
require 'moduler/base/struct_type'

module Moduler
  module Type
    module InlineStruct
      def self.extended(target)
        target.type.emit
      end

      def has_type?
        defined?(@type)
      end

      def type
        @type ||= begin
          superclass = self.class.superclass
          if superclass.respond_to?(:type) && (supertype = superclass.type)
            supertype.specialize(target: self)
          else
            type = StructType.new
            type.target = self
            type
          end
        end
      end
      #
      # def inherited(subclass)
      #   super
      #   subclass.type.emit
      # end

      #
      # If an InlineStruct class is *included*, the includer becomes an InlineStruct as well.
      #
      def included(target)
        super
        target.extend(InlineStruct)
      end

      def lazy(cache=true, &block)
        Moduler::Value::Lazy.new(cache, &block)
      end

      def attribute(name, *args, &block)
        self.type.attributes[name] = Type.new(*args, &block)
        type.emit_field(name)
      end
    end
  end
end

require 'moduler/type/struct_type'
