module Moduler
  module Type
    module TypeStruct
      def self.extended(target)
        target.include(Type) unless target == Type
      end

      def lazy(cache=true, &block)
        Moduler::LazyValue.new(cache, &block)
      end

      def attribute(name, *args, &block)
        self.type.attributes[name] = Type.new(*args, &block)
        emitter.emit_field(name, self.type.attributes[name])
      end
    end
  end
end

require 'moduler/type'