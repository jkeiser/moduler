require 'moduler/facade'
require 'moduler/facade/hash_facade'

module Moduler
  module Facade
    #
    # Creates a struct interface on top of the raw value
    #
    # Assumes the existence of raw, item_access, key_guard and value_guard
    module StructFacade
      module DSL
        def define_struct_facade(name, field_guards)
          new_class(name) do |moduler|
            moduler.inject_struct(field_guards)
          end
        end

        def inject_struct(field_guards)
          target.include StructFacade
          field_guards.each do |name, guard|
            attribute name, define_instance_variable_access(module_name(name, :field_access), guard)
          end
        end

        def define_hash_struct_facade(name, field_guards)
          new_class(name) do |moduler|
            moduler.inject_hash_struct(field_guards)
          end
        end

        def inject_hash_struct(field_guards)
          inject_struct(field_guards)

          key_guard = guard_for(Symbol)
          field_item_access = {}
          field_guards.each do |name, guard|
            field_item_access[name] = define_instance_variable_access(module_name(name, :field_access), guard)
            attribute name, field_item_access[name]
          end

          raw_eval do
            include HashFacade
            define_method(:item_access)     { |key| field_item_access[key].new(raw, key) }
            define_method(:key_in)          { |key| key_guard.coerce(key) }
            define_method(:key_out)         { |key| key_guard.coerce_out(key) }
            define_method(:value_in)        { |key, value| field_guards[key].coerce(value) }
            define_method(:value_out)       { |key, value| field_guards[key].coerce_out(value) }
          end
        end
      end
    end
  end
end
