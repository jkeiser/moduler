require 'moduler/event'
require 'moduler/base/value_context'

module Moduler
  module Base
    # Predeclare Type
    class Type
    end
    class StructType < Type
      def specialize(*args, &block)
        result = self.class.new
        result.supertype = self
        result.dsl_eval(*args, &block)
        result
      end

      def attributes(value = NO_VALUE)
        if value == NO_VALUE
          @attributes ||= {}
        else
          @attributes = value
        end
      end
      def attributes=(value)
        @attributes = value
      end

      def clone_value(value)
        if value
          value.clone
        else
          value
        end
      end

      #
      # We store structs internally with the actual hash class.
      #
      def coerce(struct)
        if struct.is_a?(Hash)
          result = target.new({})
          result.dsl_eval(struct)
          struct = result
        # TODO regretting the "LazyValue is a Proc" thing a little bit right now.
        elsif struct.is_a?(Proc) && !struct.is_a?(LazyValue)
          result = target.new({})
          result.dsl_eval(&struct)
          struct = result
        end
        super(struct)
      end

      # def coerce_key(field_name)
      #   field_name.to_sym
      # end
      #
      # def coerce_value(raw_field_name, value)
      #   attributes[raw_field_name] ? attributes[raw_field_name].coerce(value) : NO_VALUE
      # end
      #
      # def item_type_for(raw_field_name)
      #   attributes[raw_field_name]
      # end

      def self.possible_events
        super.merge(:on_struct_updated => Event)
      end

      def inline(*args, &block)
        # Determine the target from the caller
        target = block.binding.eval('self')

        # See if the target class already has a type; reuse it if so
        if target.respond_to?(:type) && target.type
          type = target.type
          type.dsl_eval(*args, &block)
        else
          type = self.specialize(*args, &block)
        end

        # Write it out!
        Moduler::Emitter.emit(type, target)
      end

      def struct(name, &block)
        # Determine the parent from the caller
        parent = block.binding.eval('self')
        if !parent.is_a?(Module)
          parent = parent.class
        end

        # See if the class already exists and reuse it if so
        target = parent.const_get(name, false)
        if target
          if target.respond_to?(:type)
            type = target.type
            type.dsl_eval(&block)
          end
        else
          target = { parent: parent, name: name }
        end

        # Write it out!
        type ||= StructType.new(*args, &block)
        Moduler::Emitter.emit(type, target)
      end

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

        if args.size == 1 && !block
          if args[0].is_a?(LazyValue)
            context.set(args[0])
            fire_on_set_raw(args[0])
            return args[0]
          end

          if args[0] == nil
            context.set(args[0])
            fire_on_set(args[0])
            return args[0]
          end
        end

        if reopen_on_call
          value = raw_value(context.get) { |v| context.set(v) }
          if value != NO_VALUE
            value = value.specialize(*args, &block)
          else
            value = default_class.new(*args, &block)
          end
        else
          value = default_class.new(*args, &block)
        end

        context.set(value)
        value = coerce_out(value)
        fire_on_set(value)
        value
      end

      attr_accessor :supertype
      attr_accessor :target
      attr_accessor :reopen_on_call
      attr_accessor :default_class
      def default_class
        @default_class || @target
      end
    end
  end
end

require 'moduler/base/type_attributes'
