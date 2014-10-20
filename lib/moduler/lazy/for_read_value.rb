require 'moduler/lazy'

module Moduler
  module Lazy
    class ForReadValue
      include Lazy

      def initialize(value, &make_writeable_block)
        @value = value
        @make_writeable_block = make_writeable_block
      end

      attr_reader :make_writeable_block

      def get
        ensure_writeable
        @value
      end

      def get_for_read
        @value.is_a?(Lazy) ? @for_read_value.get_for_read : @for_read_value
        if defined?(@for_read_value)

        else
          @value
        end
      end

      def writeable?
        defined?(@make_writeable_block)
      end

      def ensure_writeable
        if defined?(@make_writeable_block)
          @value = @value.get if @value.is_a?(Lazy)
          make_writeable_block = remove_instance_variable(:@make_writeable_block)
          make_writeable_block.call(@value)
        end
      end
    end
  end
end
