module Moduler
  module Base
    class ValueContext
      def initialize(value = NO_VALUE, &block)
        @value = value
        @block = block
      end

      def get
        @value
      end

      def set(value)
        if @block
          @block.call(value)
        else
          @value = value
        end
      end
    end
  end
end
