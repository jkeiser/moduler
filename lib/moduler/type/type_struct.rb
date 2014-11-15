module Moduler
  module Type
    module TypeStruct
      def self.extended(target)
        target.send(:include, Type) unless target == Type
      end

      def lazy(cache=true, &block)
        Moduler::Value::Lazy.new(cache, nil, &block)
      end

      def attribute(name, *args, &block)
        self.type.attributes[name] = Type.new(*args, &block)
        type.emit_field(name)
      end
    end
  end
end

require 'moduler/type'
