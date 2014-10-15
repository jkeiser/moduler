require 'moduler/base/type'
require 'moduler/base/struct_type'
require 'moduler/base/inline_struct'

# Make Type and StructType be InlineStructs.  (StructType has already
# extended from Type by this point.)
module Moduler
  module Base
    class Type
      extend InlineStruct
    end
    class StructType < Type
      emitter.emit
      attribute :reopen_on_call
      attribute :supertype
    end
  end
end
