require 'moduler/base/type'
require 'moduler/facade/set_facade'
require 'set'

module Moduler
  module Base
    class SetType < Type
      def raw_get?
        false
      end

      def clone_value(value)
        if !value
          value
        elsif item_type
          value.map { |item| item_type.clone_value(item) }
        else
          value.dup
        end
      end

      #
      # We store sets internally as sets, and slap facades on them when the
      # user requests them.
      #
      def coerce(set)
        if set.is_a?(Moduler::Facade::SetFacade)
          set = set.set
        elsif item_type
          set = set.to_set
          set.map! { |item| coerce_item(item) }
        else
          set = set.to_set
        end
        super(set)
      end

      #
      # When the user requests a set, we give them a facade (assuming there is
      # an item type on this thing).
      #
      def coerce_out(set, &cache_proc)
        set = raw_value(set, &cache_proc)
        if set == NO_VALUE
          set = Set.new
          cache_proc.call(set)
        end

        if item_type
          Moduler::Facade::SetFacade.new(set, self)
        else
          set
        end
      end

      def coerce_item(item)
        item_type ? item_type.coerce(item) : item
      end

      def coerce_item_out(item)
        item_type ? item_type.coerce_out(item) : item
      end

      def new_facade(set)
        Facade::SetFacade.new(Set.new(set.map { |item| coerce_item(item) }), self)
      end
    end
  end
end
