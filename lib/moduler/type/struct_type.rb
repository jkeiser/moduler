require 'moduler/type'
require 'moduler/facade/struct_facade'

module Moduler
  class Type
    class StructType < Type
      def initialize(*args, &block)
        @field_types ||= {}
        super
      end

      attr_accessor :field_types
      attr_accessor :reopens_on_call

      class StructFieldContext
        def initialize(hash, name)
          @hash = hash
          @name = name
        end

        def get
          if @hash.has_key?(@name)
            @hash[@name]
          else
            NO_VALUE
          end
        end

        def set(value)
          @hash[@name] = value
        end
      end

      def facade_class
        if !@facade_class
          self.facade_class = Class.new
        end
      end

      def facade_class=(value)
        @facade_class = value
        @facade_class.include(Moduler::Facade::StructFacade)
        field_types.each do |name, field_type|
          @facade_class.send(:define_method, name) do |*args, &block|
            field_type.call(StructFieldContext.new(@hash, name), *args, &block)
          end
          @facade_class.send(:define_method, "#{name}=") do |value|
            @hash[name] = field_type.coerce(value)
            # NOTE: Ruby doesn't let you return a value here anyway--it will always
            # return the passed-in value to the user.
          end
        end
      end

      #
      # Add support for the constructor form of
      #
      #   address [struct], *args, &block -> struct.new(*args, &block)
      #
      # And for reopens_on_call
      #
      def default_call(context, *args, &block)
        if args.size == 0 && !block
          # If we're doing a simple get, we just do the get.
          return super
        end

        if args[0].is_a?(facade_class)
          # If we've been passed a compatible struct class as an argument, we
          # set the value to the struct
          value = args[0]
        elsif reopens_on_call
          # Reopen the struct (or create it)
          value = raw_value(context.get) { |v| context.set(v) }
          if value == NO_VALUE
            value = facade_class.new({})
          end
        else
          value = raw_default_value { |v| context.set(v) }
          if value == NO_VALUE
            value = facade_class.new({})
          end
        end
        value.dsl_eval(*args, &block)
        coerce_out(value)
      end

      def coerce(struct)
        if struct.is_a?(Hash)
          struct = facade_class.new.dsl_eval(struct)
        elsif struct.is_a?(Proc)
          struct = facade_class.new.dsl_eval(&struct)
        end
        super(struct)
      end

      def coerce_key(field_name)
        field_name.to_sym
      end

      def coerce_value(raw_field_name, value)
        field_types[raw_field_name] ? field_types[raw_field_name].coerce(value) : NO_VALUE
      end

      def item_type_for(raw_field_name)
        field_types[raw_field_name]
      end

      def self.possible_events
        super.merge(:on_struct_updated => Event)
      end
    end
  end
end
