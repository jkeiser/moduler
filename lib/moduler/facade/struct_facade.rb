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
    end
  end
end
