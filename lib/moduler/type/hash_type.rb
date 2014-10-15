require 'moduler/base/hash_type'
require 'moduler/type'
require 'moduler/type/type_struct'

module Moduler
  module Type
    class HashType < Moduler::Base::HashType
      extend TypeStruct

      attribute :key_type,   Type
      attribute :value_type, Type
      attribute :singular,   Symbol
    end
  end
end
