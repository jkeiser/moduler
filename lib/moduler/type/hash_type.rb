require 'moduler/type'
require 'moduler/base/mix/hash_type'

module Moduler
  class Type
    class HashType < Type
      include Moduler::Base::Mix::HashType
      attribute :key_type, Type
      attribute :value_type, Type
      attribute :singular, Symbol
    end
  end
end
