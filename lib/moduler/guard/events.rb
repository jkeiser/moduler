require 'moduler/guard'

module Moduler
  module Guard
    module Events
      def self.define_event(event_name)
        define_method(event_name) do |event|
          new_module(module_name(event_name.to_s, event)) do
            include Guard
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
