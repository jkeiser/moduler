require 'moduler/base/type'
require 'moduler/base/boolean'
require 'moduler/value'

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
