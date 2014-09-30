require 'moduler/core/basic'
require 'moduler/core/facade/hash_facade'
require 'moduler/core/facade/array_facade'
require 'moduler/core/facade/set_facade'
require 'moduler/core/facade/struct_facade'
require 'moduler/core/facade/transformers'
require 'moduler/core/facade/validators'
require 'moduler/core/facade/events'

module Moduler
  module Core
    class DSL < Moduler::Core::Basic
      include Facade::HashFacade
      include Facade::ArrayFacade
      include Facade::SetFacade
      include Facade::StructFacade
      include Facade::Transformers
      include Facade::Validators
      include Facade::Events
    end
  end
end
