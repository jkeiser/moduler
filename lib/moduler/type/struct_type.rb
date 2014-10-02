require 'moduler/type'

module Moduler
  class Type
    class StructType < Type
      def initialize(*args, &block)
        @field_types ||= []
        super
      end

      attr_accessor :field_types
      attr_accessor :struct_class
      attr_accessor :reopens_on_call

      #
      # Add support for the constructor form of
      #
      #   address :state => 'WA' do
      #     city 'Seattle'
      #   end
      #
      # And for reopens_on_call
      #
      def default_call(context, *args, &block)
        if args.size <= 1 && (args.size == 1 || block)
          # If they passed a hash or did not pass arguments, we need to grab a
          # new copy of this thing.
          if args[0].is_a?(Hash) || args.size == 0
            if reopens_on_call
              if context.has_value?
                result = context.get.dsl_eval(*args, &block)
              elsif default_value
                result = get_default.dsl_eval(*args, &block)
              end
            end
            result ||= struct_class.new(*args, &block)
          else
            if block
              result = args[0].dsl_eval(&block)
            else
              result = args[0]
            end
          end
          context.set(coerce(result))
        else
          super
        end
      end

      def call_field(field_name, context, *args, &block)
        if field_types[field_name]
          field_types[field_name].call(context, *args, &block)
        end
      end

      def coerce(struct)
        if struct.is_a?(Hash)
          struct_class.new(struct)
        elsif struct.is_a?(Proc)
          struct_class.new(&struct)
        end
        super(set)
      end

      def coerce_key(field_name)
        field_name.to_sym
      end

      def coerce_value(raw_field_name, value)
        field_types[raw_field_name] ? field_types[raw_field_name].coerce(value) : value
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
