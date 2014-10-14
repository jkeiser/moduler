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

      def attribute(name, type=nil)
        self.type.dsl_eval { attributes[name] = type }
        emitter.emit_field(name, self.type.attributes[name])
      end
    end

    # Make Type and StructType be InlineStructs.  (StructType has already
    # extended from Type by this point.)
    class Type
      extend InlineStruct
    end
    class StructType < Type
      emitter.emit
      attribute :specialize_from, Type.new.tap { |t| t.default { puts "Unlazy #{self}"; self } }
      attribute :reopen_on_call
      attribute :supertype
    end
  end
end
