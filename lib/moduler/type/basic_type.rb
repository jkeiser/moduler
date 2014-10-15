require 'moduler/base/type'
require 'moduler/base/boolean'
require 'moduler/base/value_context'
require 'moduler/lazy_value'

module Moduler
  module Type
    module TypeStruct; end
    class BasicType < Moduler::Base::Type
      extend TypeStruct
      include Type
    end
  end
end

require 'moduler/type/type_struct'
