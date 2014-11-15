require 'moduler/value'

module Moduler
  module Value
    class Lazy
      include Value

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

      def raw(context)
        if defined?(@cached)
          @cached
        else
          value = context ? context.instance_eval(&@block) : @block.call
          value = value.raw(context) if value.is_a?(Value)
          @cached = value if @cache
          value
        end
      end

      def raw_read(context)
        if defined?(@cached)
          @cached
        else
          value = context ? context.instance_eval(&@block) : @block.call
          value = value.raw_read(context) if value.is_a?(Value)
          @cached = value if @cache
          value
        end
      end
    end
  end
end
