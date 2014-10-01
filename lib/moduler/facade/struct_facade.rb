require 'moduler/facade'
require 'moduler/facade/hash_facade'

module Moduler
  module Facade
    #
    # Creates a struct interface on top of the raw value
    #
    # Assumes the existence of raw, item_access, key_guard and value_guard
    module StructFacade
      include Facade

      module DSL
        def define_struct_facade(name, field_guards)
          new_module(name) do |moduler|
            moduler.inject_struct(field_guards)
          end
        end

        def inject_struct(field_guards)
          dsl_eval do
            include StructFacade
            field_guards.each do |name, guard|
              attribute name, guard
            end
          end
        end

        def define_hash_struct_facade(name, field_guards)
          new_module(name) do |moduler|
            moduler.inject_hash_struct(field_guards)
          end
        end

        def inject_hash_struct(field_guards)
          inject_struct(field_guards)

          key_guard = guard_for(Symbol)
          include HashFacade
          field_item_access = {}
          field_guards.each do |name, guard|
            if guard
              field_item_access[name] = define_instance_variable_access(module_name(name, :field_access), guard)
            end
          end
          define_method(:key_guard)       { key_guard }
          define_method(:item_access_for) { |key| field_item_access[key].new(raw, key) }
          define_method(:value_guard_for) { |key| field_guards[key] }
        end
      end
    end
  end
end
