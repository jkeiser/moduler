require 'moduler/event'
require 'moduler/base/specializable_type'
require 'moduler/facade/struct_facade'
require 'moduler/base/attribute'
require 'moduler/base/value_context'

module Moduler
  module Base
    module Mix
      module StructType
        include Moduler::Base::SpecializableType

        # Attributes:
        # attributes
        # reopens_on_call
        # specialize_from

        def facade_class
          if !@facade_class
            # TODO choose a name so at least we can see what it is.
            self.facade_class = Class.new do
              def to_s
                "StructFacade:#{super}"
              end
              def inspect
                "StructFacade:#{super}"
              end
            end
          end
          @facade_class
        end

        def facade_class=(value)
          @facade_class = value
          emit_to(@facade_class)
        end

        def emit_to(target)
          target.include(Moduler::Facade::StructFacade)
          attributes.each do |name, type|
            if type
              type.emit_attribute(target, name)
            else
              type_system.emit_attribute(target, name)
            end
          end
        end

        def restore_facade(raw_value)
          facade_class.new(raw_value)
        end

        def new_facade(value)
          coerce(value)
        end

        def specialize_from?(value)
          if value.is_a?(facade_class)
            facade_class.new({})
          end
        end

        def specialize_from
          facade_class.new({})
        end
        def reopen_on_call
          false
        end

        #
        # We store structs internally with the actual hash class.  TODO consider
        # just leaving them hashes and slapping up the facade when needed ...
        #
        def coerce(struct)
          if struct.is_a?(Hash)
            result = facade_class.new({})
            result.dsl_eval(struct)
            struct = result
          elsif struct.is_a?(Proc)
            result = facade_class.new({})
            result.dsl_eval(&struct)
            struct = result
          end
          super(struct)
        end

        def coerce_key(field_name)
          field_name.to_sym
        end

        def coerce_value(raw_field_name, value)
          attributes[raw_field_name] ? attributes[raw_field_name].coerce(value) : NO_VALUE
        end

        def item_type_for(raw_field_name)
          attributes[raw_field_name]
        end

        def self.possible_events
          super.merge(:on_struct_updated => Event)
        end

        def attribute(name, *args, &block)
          attributes[name] = type_system.type(*args, &block)
        end
      end
    end
  end
end
