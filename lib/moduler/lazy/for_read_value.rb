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
        @value.is_a?(Lazy) ? @value.get_for_read : @value
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

      def in_context(context)
        if @value.is_a?(Lazy)
          self.class.new(@value.in_context(context), @make_writeable_block)
        else
          self
        end
      end
    end
  end
end
