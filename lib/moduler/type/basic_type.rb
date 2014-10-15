require 'moduler/base/type'
require 'moduler/base/boolean'
require 'moduler/base/value_context'
require 'moduler/lazy_value'

module Moduler
  module Type
    class BasicType < Moduler::Base::Type
      require 'moduler/type/type_struct'
      extend TypeStruct
    end
  end
end
