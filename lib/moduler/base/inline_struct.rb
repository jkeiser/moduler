require 'moduler/base/struct_type'
require 'moduler/emitter'

module Moduler
  module Base
    module InlineStruct
      def self.extended(target)
        target.emitter.emit
      end

      def emitter
        @emitter ||= begin
          if @type
            type = @type
          elsif respond_to?(:type) && self.type
            type = self.type.specialize
          else
            type = StructType.new
          end
          Moduler::Emitter::StructEmitter.new(type, self)
        end
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
      end

      def attribute(name, type=nil)
        if type && !type.is_a?(Type)
          raise "#{type} must be a Type"
        end
        self.type.dsl_eval { attributes[name] = type }
        emitter.emit_field(name, self.type.attributes[name])
      end
    end
  end
end
