require 'moduler/event'

module Moduler
  module DSL
    module Event
      def on_set(&block)
      end
      class OnSetEvent < Event
        attr_reader :event
        def on_set
      end
      class OnArrayUpdatedEvent < Event
        attr_reader :event

        define_method(event_name) do |event|
          new_class(module_name(event_name.to_s, event), ) do
            define_method event_name do |*args|
              super(value)
              event.fire_in_context(self, *args)
            end
          end
        end
      end

      define_event(:on_set)
      define_event(:on_array_updated)
      define_event(:on_hash_updated)
      define_event(:on_set_updated)
      define_event(:on_struct_updated)
    end
  end
end
