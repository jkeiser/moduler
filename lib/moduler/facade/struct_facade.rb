require 'moduler/facade'
require 'moduler/specializable'
require 'moduler/attributable'

module Moduler
  module Facade
    module StructFacade
      include Facade
      include Specializable
      include Attributable

      def ==(other)
        other.is_a?(self.class) && @hash == other.instance_variable_get(:@hash)
      end
      def to_hash
        @hash
      end
    end
  end
end
