require 'moduler/dsl/basic'

module Moduler
  module DSL
    class DSL < Moduler::DSL::Basic

      require 'moduler/dsl/attributes'
      include Attributes

      require 'moduler/facade/accessor/instance_variable_access'
      require 'moduler/facade/accessor/array_item_access'
      require 'moduler/facade/accessor/hash_item_access'
      require 'moduler/facade/accessor/value_access'
      include Facade::Accessor::InstanceVariableAccess::DSL
      include Facade::Accessor::ArrayItemAccess::DSL
      include Facade::Accessor::HashItemAccess::DSL
      include Facade::Accessor::ValueAccess::DSL

      require 'moduler/facade/raw_facade'
      require 'moduler/facade/hash_facade'
      require 'moduler/facade/array_facade'
      require 'moduler/facade/set_facade'
      require 'moduler/facade/struct_facade'
      include Facade::RawFacade::DSL
      include Facade::HashFacade::DSL
      include Facade::ArrayFacade::DSL
      include Facade::SetFacade::DSL
      include Facade::StructFacade::DSL

      require 'moduler/facade/transformers'
      require 'moduler/facade/validators'
      require 'moduler/facade/events'
      include Facade::Transformers
      include Facade::Validators
      include Facade::Events
    end
  end
end
