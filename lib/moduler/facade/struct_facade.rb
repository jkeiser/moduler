require 'moduler/facade'

module Moduler
  module Facade
    module StructFacade
      include Facade
      include Specializable
      def initialize(hash, *args, &block)
        @hash = hash
        super(*args, &block)
      end
      def ==(other)
        @hash == other.instance_variable_get(:@hash)
      end
    end
  end
end
