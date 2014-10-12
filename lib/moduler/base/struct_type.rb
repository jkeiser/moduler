require 'moduler/event'
require 'moduler/base/specializable_type'
require 'moduler/base/value_context'

module Moduler
  module Base
    module StructType
      include Moduler::Base::SpecializableType

      def clone_value(value)
        if value
          value.clone
        else
          value
        end
      end

      # def specialize_from?(value)
      #   if value.is_a?(target)
      #     value
      #   end
      # end
      # def specialize_from
      #   target.new
      # end
      # def reopen_on_call
      #   false
      # end

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


      # Things you should override
      def attributes
        @attributes ||= {}
      end
      def attribute(name, *args, &block)
        attributes[name] = type_system.type(*args, &block)
      end
    end
  end
end
