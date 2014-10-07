require 'moduler/type'
require 'moduler/facade/struct_facade'

module Moduler
  class Type
    class StructType < Type
      def initialize(*args, &block)
        @field_types ||= {}
        @construction_start_value = NO_VALUE
        super
      end

      # Attributes:
      # field_types
      # reopens_on_call
      # construction_start_value

      attr_accessor :field_types
      attr_accessor :reopens_on_call

      #
      # The default value gets set the same way as the value would--you can use
      # the same expressions you would otherwise.
      #
      def construction_start_value(*args, &block)
        if args.size == 0 && !block && @construction_start_value == NO_VALUE
          NO_VALUE
        else
          default_call(DefaultValueContext.new(self), *args, &block)
        end
      end
      def construction_start_value=(value)
        @construction_start_value = coerce(value)
      end

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
        @facade_class
      end

      def facade_class=(value)
        @facade_class = value
        @facade_class.include(Moduler::Facade::StructFacade)
        field_types.each do |name, field_type|
          @facade_class.send(:define_method, name) do |*args, &block|
            result = field_type.call(StructFieldContext.new(@hash, name), *args, &block)
            result == NO_VALUE ? nil : result
          end
          @facade_class.send(:define_method, "#{name}=") do |value|
            value = field_type.coerce(value)
            @hash[name] = value
            field_type.fire_on_set_raw(value)
            # NOTE: Ruby doesn't let you return a value here anyway--it will always
            # return the passed-in value to the user.
          end
        end
      end

      def restore_facade(raw_value)
        facade_class.new(raw_value)
      end

      def new_facade(value)
        coerce(value)
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

        if args[0].is_a?(LazyValue)
          context.set(args[0])
          fire_on_set_raw(args[0])
          return args[0]
        end

        if args[0].is_a?(facade_class)
          # If we've been passed a compatible struct class as an argument, we
          # set the value to the struct
          value = args[0]
        else
          value = start_construction(context)
        end

        value.dsl_eval(*args, &block)
        value = coerce_out(value)
        fire_on_set(value)
        value
      end

      def start_construction(context)
        if reopens_on_call
          # Reopen the struct (or create it)
          value = raw_value(context.get) { |v| context.set(v) }
        else
          value = raw_default_value { |v| context.set(v) }
        end
        if value == NO_VALUE
          value = construction_start_value
        end

        if value == NO_VALUE
          value = facade_class.new({})
          context.set(value)
        end
        value
      end

      def coerce(struct)
        if struct.is_a?(Hash)
          result = facade_class.new({})
          result.dsl_eval(struct)
          struct = result
        elsif struct.is_a?(Proc)
          result = facade_class.new({})
          result.dsl_eval(&struct)
          struct = result
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
