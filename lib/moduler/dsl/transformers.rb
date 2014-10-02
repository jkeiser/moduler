module Moduler
  module DSL
    module Transformers
      def on_call(block)
        new_module(module_name(:on_call, block)) do
          include Guard
          define_method :call, &block
        end
      end

      def standard_call
        StandardCall
      end

      def default_value(value)
        new_module(module_name(:default_value, value)) do
          include Guard
          def get
            has_raw? ? super : self.class.coerce_out(value)
          end
        end
      end

      def lazy_handler
        LazyHandler
      end

      def coerce(block)
        new_module(module_name(:coerce, block)) do
          include Coercer
          def coerce(value)
            super(block.call(value))
          end
        end
      end

      def coerce_out(block)
        new_module(module_name(:coerce_out, block)) do
          include Coercer
          def coerce_out(value)
            block.call(super)
          end
        end
      end

      module LazyHandler
        include Guard

        def set(value)
          if value.is_a?(LazyValue)
            self.raw = value # Set without coercion; the coercion will happen on get.
          else
            super(value)
          end
        end

        def get
          if raw.is_a?(LazyValue)
            value = coerce(raw.call)
            if raw.cache
              self.raw = value
              super
            else
              coerce_out(value)
            end
          else
            super
          end
        end
      end
    end
  end
end
