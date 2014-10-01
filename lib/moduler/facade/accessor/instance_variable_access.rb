require 'moduler/facade/guard'

module Moduler
  module Facade
    module Accessor
      #
      # Represents an instance variable access (obj.@name).  The access is not resolved
      # until the point of get/set.
      #
      module InstanceVariableAccess
        include Accessor

        def initialize(instance, name)
          @instance = instance
          @name = "@#{name}".to_sym
        end

        def raw
          @instance.instance_variable_get(@name)
        end
        def raw=(value)
          @instance.instance_variable_set(@name, value)
        end
        def has_raw?
          @instance.instance_variable_defined?(@name, value)
        end

        module DSL
          def define_instance_variable_access(name, guard)
            new_class(name, guard) { include InstanceVariableAccess }.target
          end
        end
      end
    end
  end
end
