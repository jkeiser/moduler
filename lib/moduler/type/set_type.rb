require 'moduler/base/set_type'
require 'moduler/type/type_struct'
require 'moduler/type'

module Moduler
  module Type
    class SetType < Moduler::Base::SetType
      extend TypeStruct

      attribute :item_type, Type
      attribute :singular, Symbol
    end
  end
end
