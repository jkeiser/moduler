require 'moduler/lazy'

module Moduler
  module Lazy
    class Value
      include Moduler::Lazy

      def initialize(cache=false, &block)
        @cache = cache
        @block = block
      end

      def cache?
        @cache
      end

      def cached?
        defined?(@cached)
      end

      def get
        if defined?(@cached)
          @cached
        else
          value = @block.call
          if value.is_a?(Lazy)
            value = value.get
          end
          @cached = value if @cache
          value
        end
      end
    end
  end
end
