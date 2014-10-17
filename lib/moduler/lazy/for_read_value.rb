require 'moduler/lazy/value'

module Moduler
  module Lazy
    class ForReadValue < Value
      def initialize(for_read_value, &writeable_block)
        super(&writeable_block)
        @for_read_value = for_read_value
      end

      def get
        remove_instance_variable(:@for_read_value) if defined?(@for_read_value)
        super
      end

      def get_for_read
        if defined?(@for_read_value)
          @for_read_value.is_a?(Lazy) ? @for_read_value.get_for_read : @for_read_value
        else
          get
        end
      end
    end
  end
end
