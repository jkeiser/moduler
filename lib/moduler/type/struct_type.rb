require 'moduler/base/struct_type'
require 'moduler/base/value_context'
require 'moduler/type/type_struct'

module Moduler
  module Type
    class StructType < Moduler::Base::StructType
      extend TypeStruct

      def attribute(name, *args, &block)
        context = Base::ValueContext.new(attributes[name]) { |v| attributes[name] = v }
        attributes[name] = Type.new(*args, &block)
      end

      # TODO declare attributes with :no_emit, once we support :no_emit
      #attribute :attributes#, :singular => :attribute
      attribute :default_class,  Struct,     :default => lazy(false) { puts "default class #{target}"; target }
      attribute :reopen_on_call, Boolean,    :default => false
      attribute :supertype,      Type
    end
  end
end
