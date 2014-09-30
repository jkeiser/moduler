module Moduler
  module Core
    module Transformers
      def on_call(block)
        moduler.define_module(module_name("on_call", block)) do
          define_method :call, &block
        end
      end

      def standard_call
        StandardCall
      end

      def default_value(value)
        moduler.define_module(module_name("default_value", value)) do
          def get
            set? ? super : class.coerce_out(value)
          end
        end
      end

      def lazy_handler
        LazyHandler
      end

      def coerce(block)
        moduler.define_module(module_name("coerce", block)) do
          def self.coerce(value)
            super(block.call(value))
          end
        end
      end

      def coerce_out(block)
        moduler.define_module(module_name("coerce_out", block)) do
          def self.coerce_out(value)
            block.call(super)
          end
        end
      end

      module StandardCall
        def call(value = Moduler::NO_VALUE, &block)
          if value == Moduler::NO_VALUE
            if block
              set(block)
            else
              get
            end
          elsif block
            raise ArgumentError, "Both value and block specified to attribute call"
          else
            set(value)
          end
        end
      end

      module LazyHandler
        def self.coerce(value)
          if value.is_a?(LazyValue)
            return value
          end
          super
        end

        def self.coerce_out(value)
          if value.is_a?(LazyValue)
            result = value.call
            if value.cache
              set(result)
            end
            super(result)
          else
            super
          end
        end
      end
    end
  end
end
