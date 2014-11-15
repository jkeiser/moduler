module Moduler
  module Base
    # Predeclare Type
    class Type
    end
    class StructType < Type
      def specialize(*args, &block)
        result = self.class.new
        result.supertype = self
        result.set_attributes(*args, &block)
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

      def raw_default
        if store_in_hash
          defined?(@default) ? @default : {}
        else
          @default
        end
      end

      #
      # We store structs internally with the actual hash class.
      #
      def coerce(value, context)
        if store_in_hash && !value.nil?
          if !value.respond_to?(:to_hash)
            raise ValidationFailed.new(["#{value} must be a hash"])
          end
          value.to_hash
        elsif value.is_a?(Hash)
          value = target.new(value)
        elsif value.is_a?(Proc)
          value = target.new(&value)
        end
        super
      end

      def coerce_out(value, context)
        if store_in_hash && !value.nil?
          target.new(value, context, true)
        else
          super
        end
      end

      def inline(*args, &block)
        # Determine the target from the caller
        target = block.binding.eval('self')

        # See if the target class already has a type; reuse it if so
        if target.respond_to?(:type) && target.type
          type = target.type
          type.set_attributes(*args, &block)
        else
          type = self.specialize(*args, &block)
        end

        # Write it out!
        type.emit
        type
      end

      def struct(name, *args, &block)
        # Determine the parent from the caller
        parent = block.binding.eval('self')
        if !parent.is_a?(Module)
          parent = parent.class
        end

        # See if the class already exists and reuse it if so
        if parent.const_defined?(name, false)
          target = parent.const_get(name, false)
          if target.respond_to?(:type)
            type = target.type
            type.set_attributes(&block)
          end
        else
          target = { parent: parent, name: name }
        end

        # Write it out!
        type ||= self.class.new(*args, &block)
        type.target = target
        type.emit
        type
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
      def construct_raw(context, *args, &block)
        if args.size == 0 && !block
          # If we're doing a simple get, we just do the get.
          return super
        end

        if args.size == 1 && !block
          if args[0].is_a?(Value)
            return args[0]
          end

          if args[0] == nil
            return coerce(args[0], context)
          end
        end

        if store_in_hash
          if args.size > 1
            raise ArgumentError.new("Cannot create a hash struct with more than one argument")
          end
          (default_class || target).new(args[0], context, false, &block)
        else
          (default_class || target).new(*args, &block)
        end
      end

      attr_accessor :supertype
      attr_accessor :target
      attr_accessor :reopen_on_call
      attr_accessor :default_class
      attr_accessor :store_in_hash
    end
  end
end

require 'moduler/base/struct_emitter'
require 'moduler/base/type_attributes'
