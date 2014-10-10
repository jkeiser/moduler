require 'moduler/type'
require 'moduler/base/mix/array_type'

module Moduler
  module Base
    class Type
      class ArrayType < Type
        include Moduler::Base::Mix::ArrayType
        attribute :index_type, Type
        attribute :element_type, Type
      end
    end
  end
end
