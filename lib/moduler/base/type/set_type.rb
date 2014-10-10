require 'moduler/type'
require 'moduler/base/mix/set_type'

module Moduler
  module Base
    class Type
      class SetType < Type
        include Moduler::Base::Mix::SetType
        attribute :item_type, Type
      end
    end
  end
end
