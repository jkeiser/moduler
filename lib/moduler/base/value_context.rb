module Moduler
  module Base
    class ValueContext
      def initialize(value=NO_VALUE)
        @value = value
      end

      attr_reader :value

      def get
        @value
      end
      def set(value)
        @value = value
      end
    end
  end
end
