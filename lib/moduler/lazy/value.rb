require 'moduler/lazy'

module Moduler
  module Lazy
    class Value
      include Moduler::Lazy

      def initialize(cache=false, context=nil, &block)
        @cache = cache
        @context = context
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
          value = @context ? @context.instance_eval(&@block) : @block.call
          if value.is_a?(Lazy)
            value = value.get
          end
          @cached = value if @cache
          value
        end
      end

      # TODO some lazy values might not want to be copied around or instance_eval'd--
      # we should give them an option so they can have a master cache or avoid
      # instance_eval.
      def in_context(context)
        Lazy::Value.new(cache?, context, &@block)
      end
    end
  end
end
