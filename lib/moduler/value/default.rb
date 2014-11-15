require 'moduler/value/basic'

module Moduler
  module Value
    class Default
      include Value::Basic

      def initialize(value, &make_writeable_block)
        super(value)
        @make_writeable_block = make_writeable_block
      end

      attr_reader :make_writeable_block

      def writeable?
        !@make_writeable_block
      end

      def ensure_writeable(context)
        super
        if defined?(@make_writeable_block)
          @raw = @raw.raw(context) if @raw.is_a?(Value)
          make_writeable_block = remove_instance_variable(:@make_writeable_block)
          make_writeable_block.call(@raw)
        end
      end
    end
  end
end
