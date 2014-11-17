require 'moduler/base/struct_type'

module Moduler
  module Base
    module InlineStruct
      def self.extended(target)
        target.type.emit
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

      def has_type?
        defined?(@type)
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

      def attribute(name, type=nil)
        if type && !type.is_a?(Type)
          raise "#{type} must be a Type"
        end
        self.type.attributes[name] = type
        self.type.emit_field(name)
      end
    end
  end
end
