require 'moduler/base/array_type'
require 'moduler/type/type_struct'
require 'moduler/type'

module Moduler
  module Type
    class ArrayType < Moduler::Base::ArrayType
      extend TypeStruct

      attribute :index_type, Type
      attribute :element_type, Type
      attribute :singular, Symbol
    end
  end
end
