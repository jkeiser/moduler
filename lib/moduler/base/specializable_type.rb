require 'moduler/base/attribute'

module Moduler
  module Base
    module SpecializableType
      #
      # Add support for the constructor form of
      #
      #   address <struct> -> set to struct
      #   address <struct>, *args, &block -> address.specialize(*args, &block)
      #   address *args, &block -> address.new(*args, &block)
      #   When reopens_on_call is true
      #   address *args, &block -> (current_value || default).specialize(*args, &block)
      #
      def default_call(context, *args, &block)
        if args.size == 0 && !block
          # If we're doing a simple get, we just do the get.
          return super
        end

        if args[0].is_a?(LazyValue)
          context.set(args[0])
          fire_on_set_raw(args[0])
          return args[0]
        end

        # Figure out if we want to specialize a value, or start anew
        value = start_construction_from?(args[0])
        if value
          args.shift
        elsif reopen_on_call
          value = raw_value(context.get) { |v| context.set(v) }
          value = start_with if value == NO_VALUE
        else
          value = start_with
        end

        value = value.specialize(*args, &block)
        context.set(value)
        value = coerce_out(value)
        fire_on_set(value)
        value
      end

      def start_with
        Type.empty
      end
      def reopen_on_call
        true
      end
    end
  end
end