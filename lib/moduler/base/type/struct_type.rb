require 'moduler/type'
require 'moduler/base/mix/struct_type'

module Moduler
  module Base
    class Type
      class StructType < Type
        include Moduler::Base::Mix::StructType
        attribute :attributes, Hash[Symbol => Type]
      end
    end
  end
end
