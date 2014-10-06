require 'moduler/type'

module Moduler
  class Type
    module CoercerOut
      def coerce_out(value)
        raise NotImplementedError
      end

      def self.create(&block)
        Class.new do
          include CoercerOut
          define_method(:coerce_out, &block)
        end.new
      end
    end
  end
end
