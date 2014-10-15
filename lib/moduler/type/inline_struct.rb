require 'moduler/base/inline_struct'
require 'moduler/base/struct_type'

module Moduler
  module Type
    module InlineStruct
      def self.extended(target)
        target.emitter.emit
      end

      def emitter
        @emitter ||= begin
          if @type
            type = @type
          elsif respond_to?(:type) && self.type
            if type.is_a?(Moduler::Base::StructType)
              type = StructType.new(type.to_hash)
            else
              type = self.type.specialize
            end
          else
            type = StructType.new
          end
        end
        @emitter = Moduler::Emitter::StructEmitter.new(type, self)
      end

      def inherited(subclass)
        super
        subclass.emitter.emit
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
require 'moduler/emitter'
