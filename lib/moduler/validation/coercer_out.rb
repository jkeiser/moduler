require 'moduler/type'

module Moduler
  module Validation
    module CoercerOut
      def coerce_out(value)
        raise NotImplementedError
      end

      def self.create(&block)
        Class.new do
          include CoercerOut
          define_method(:coerce_out, &block)
          def to_s
            "CoercerOut #{super}"
          end
        end.new
      end
    end
  end
end
