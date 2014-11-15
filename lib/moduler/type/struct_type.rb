require 'moduler/base/struct_type'
require 'moduler/type/type_struct'
require 'moduler/errors'

module Moduler
  module Type
    class StructType < Moduler::Base::StructType
      extend TypeStruct

      def coerce(value, context)
        value = super
        if !value.is_a?(Value)
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
        attributes[name] = Type.new(*args, &block)
      end

      # TODO declare attributes with :no_emit, once we support :no_emit
      #attribute :attributes#, :singular => :attribute
      attribute :default_class,  :kind_of => Module, :validators => proc { |c| c <= Struct }#,     :default => lazy(false) { |v| v.target }
      attribute :reopen_on_call, Boolean
      attribute :supertype,      Type
      attribute :target,         :kind_of => [ Module, Hash ]
      attribute :store_in_hash,  Boolean
    end
  end
end
