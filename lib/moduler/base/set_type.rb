require 'moduler/base/type'
require 'moduler/facade/set_facade'
require 'set'

module Moduler
  module Base
    class SetType < Type
      def raw_default
        defined?(@default) ? @default : Set.new
      end

      #
      # We store sets internally as Sets, and slap facades on them when the
      # user requests them.
      #
      def coerce(value, context)
        if value.is_a?(Moduler::Facade::SetFacade)
          if value.type != self && item_type
            value = value.map { |item| item_type.to_raw(item, context) }.to_set
          else
            value = value.raw(context)
          end
        elsif !value.nil?
          if value.respond_to?(:to_set)
            value = value.to_set
          else
            value = Set.new([ value ])
          end
          if item_type
            value = value.map { |item| item_type.to_raw(item, context) }.to_set
          end
        end
        super
      end

      #
      # When the user requests the set, we give them a facade to protect the
      # values, assuming there is any item_type to protect.
      #
      def coerce_out(value, context)
        if value.is_a?(Value) || (value && item_type)
          Facade::SetFacade.new(value, self, context)
        else
          value
        end
      end

      def construct_raw(context, *values)
        if values.size == 1
          if values[0].is_a?(Value) || values[0].respond_to?(:to_set) || values[0].nil?
            value = values[0]
          else
            value = values
          end
        else
          value = values
        end
        coerce(value, context)
      end

      def clone_value(value)
        if !value
          value
        elsif item_type
          Set.new(value.map { |item| item_type.clone_value(item) })
        else
          value.dup
        end
      end

      def emit(parent=nil, name=nil)
        item_type.emit(parent, name) if item_type
      end
    end
  end
end
