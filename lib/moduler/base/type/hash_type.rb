require 'moduler/type'
require 'moduler/base/mix/hash_type'

module Moduler
  module Base
    class Type
      class HashType < Type
        include Moduler::Base::Mix::HashType
        attribute :key_type, Type
        attribute :value_type, Type
      end
    end
  end
end
