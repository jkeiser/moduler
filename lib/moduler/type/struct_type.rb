require 'moduler/base/struct_type'
require 'moduler/base/value_context'
require 'moduler/type/type_struct'
require 'moduler/errors'

module Moduler
  module Type
    class StructType < Moduler::Base::StructType
      extend TypeStruct

      def coerce(value)
        value = super(value)
        if !value.is_a?(LazyValue)
          errors = []
          attributes.each do |name,type|
            if type.required && !value.is_set?(name)
              errors << "Missing required field #{name}"
            end
          end
          raise ValidationFailed.new(errors) if errors.size > 0
        end
        value
      end

      def specialize(type=nil, options=nil, &block)
        if !options && Type.is_options?(type)
          options = type
          type = nil
        end
        if options
          options.merge!(supertype: self)
        else
          options = { supertype: self }
        end
        Type.new(type, options, self.class, &block)
      end

      def attribute(name, *args, &block)
        context = Base::ValueContext.new(attributes[name]) { |v| attributes[name] = v }
        attributes[name] = Type.new(*args, &block)
      end

      # TODO declare attributes with :no_emit, once we support :no_emit
      #attribute :attributes#, :singular => :attribute
      attribute :default_class,  Struct,     :default => lazy(false) { target }
      attribute :reopen_on_call, Boolean,    :default => false
      attribute :supertype,      Type
      attribute :target,         Module
    end
  end
end
