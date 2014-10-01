require 'moduler/dsl/basic'

module Moduler
  module DSL
    class DSL < Moduler::DSL::Basic

      require 'moduler/dsl/attributes'
      include Attributes

      require 'moduler/facade/instance_variable_access'
      require 'moduler/facade/array_item_access'
      require 'moduler/facade/hash_item_access'
      require 'moduler/facade/value_access'
      include Facade::InstanceVariableAccess::DSL
      include Facade::ArrayItemAccess::DSL
      include Facade::HashItemAccess::DSL
      include Facade::ValueAccess::DSL

      require 'moduler/facade/hash_facade'
      require 'moduler/facade/array_facade'
      require 'moduler/facade/set_facade'
      require 'moduler/facade/struct_facade'
      include Facade::HashFacade::DSL
      include Facade::ArrayFacade::DSL
      include Facade::SetFacade::DSL
      include Facade::StructFacade::DSL

      require 'moduler/guard/transformers'
      require 'moduler/guard/validators'
      require 'moduler/guard/events'
      include Guard::Transformers
      include Guard::Validators
      include Guard::Events
    end
  end
end
