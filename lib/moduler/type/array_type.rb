require 'moduler/base/array_type'
require 'moduler/type/type_struct'
require 'moduler/type'

module Moduler
  module Type
    class ArrayType < Moduler::Base::ArrayType
      extend TypeStruct

      attribute :index_type, Type
      attribute :element_type, Type

      def construct_raw(*values)
        # If the user passes nil or [...] as arguments, we construct like normal.
        # Otherwise we use the multivalued constructor form.
        if values[0].respond_to?(:to_a) || values[0].nil?
          super
        else
          coerce(values)
        end
      end
    end
  end
end
