require 'moduler/base/type'
require 'moduler/facade/set_facade'
require 'set'

module Moduler
  module Base
    class SetType < Type
      def raw_default
        result = super
        if result.nil? && !nullable
          result = Set.new
        end
        result
      end

      #
      # We store sets internally as Sets, and slap facades on them when the
      # user requests them.
      #
      def coerce(value)
        if value.is_a?(Moduler::Facade::SetFacade)
          if value.type != self && item_type
            value = value.map { |item| item_type.to_raw(item) }.to_set
          else
            value = value.raw_write
          end
        elsif !value.nil?
          if value.respond_to?(:to_set)
            value = value.to_set
          end
          if item_type
            value = value.map { |item| item_type.to_raw(item) }.to_set
          end
        end
        super(value)
      end

      #
      # When the user requests the set, we give them a facade to protect the
      # values, assuming there is any item_type to protect.
      #
      def coerce_out(set)
        if set && item_type
          Facade::SetFacade.new(set, self)
        else
          set
        end
      end

      def new_facade(set)
        Facade::SetFacade.new(to_raw(set), self)
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
    end
  end
end
