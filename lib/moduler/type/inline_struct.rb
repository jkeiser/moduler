require 'moduler/base/inline_struct'
require 'moduler/base/struct_type'

module Moduler
  module Type
    module InlineStruct
      def self.extended(target)
        target.type.emit
      end

      def type
        @type ||= begin
          if superclass.respond_to?(:type) && (supertype = super)
            StructType.new(supertype: supertype, target: self)
          else
            StructType.new(target: self)
          end
        end
      end

      def inherited(subclass)
        super
        subclass.type.emit
      end

      #
      # If an InlineStruct class is *included*, the includer becomes an InlineStruct as well.
      #
      def included(target)
        super
        target.extend(InlineStruct)
        subclass.emitter.emit
      end
    end
  end
end

require 'moduler/type/struct_type'
