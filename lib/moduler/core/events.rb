module Moduler
  module Core
    module Events
      def self.define_event(event_name, on_method=nil)
        on_method ||= event_name.to_s[3..-1]
        define_method(event_name) do |event|
          moduler.define_module(module_name(event_name.to_s, event), Transform) do
            method event_name { |value| super(value); event.fire_in_context(self) }
          end
        end
      end

      define_event(:on_set)
      define_event(:on_update_array)
      define_event(:on_update_hash)
      define_event(:on_update_set)
      define_event(:on_update_struct)
    end
  end
end
