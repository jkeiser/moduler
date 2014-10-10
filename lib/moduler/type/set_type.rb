require 'moduler/type'
require 'moduler/base/mix/set_type'

module Moduler
  class Type
    class SetType < Type
      include Moduler::Base::Mix::SetType
      attribute :item_type, Type
      attribute :singular, Symbol
    end
  end
end
