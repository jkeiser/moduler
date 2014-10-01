require 'moduler/guard'

module Moduler
  module Facade
    #
    # Represents an instance variable access (obj.@name).  The access is not resolved
    # until the point of get/set.
    #
    module InstanceVariableAccess
      include Facade
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
      def set?
        @instance.instance_variable_defined?(@name, value)
      end

      module DSL
        def define_instance_variable_access(name, guard)
          new_class(name) do |moduler|
            moduler.include_guards([guard])
            include InstanceVariableAccess
          end
        end
      end
    end
  end
end
