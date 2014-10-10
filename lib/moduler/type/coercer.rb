require 'moduler/type'

module Moduler
  class Type
    module Coercer
      def coerce(value)
        raise NotImplementedError
      end

      def self.create(&block)
        Class.new do
          include Coercer
          define_method(:coerce, &block)
          def to_s
            "Coercer #{super}"
          end
        end.new
      end
    end
  end
end
