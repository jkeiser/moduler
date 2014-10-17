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
          case @for_read_value
          when ForReadValue
            @for_read_value.get_for_read
          when Lazy
            @for_read_value.get
          else
            @for_read_value
          end
        else
          get
        end
      end
    end
  end
end
