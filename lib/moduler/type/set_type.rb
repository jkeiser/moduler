require 'moduler/type'
require 'moduler/facade/set_facade'
require 'set'

module Moduler
  class Type
    class SetType < Type
      attr_accessor :item_type

      def facade_class
        Moduler::Facade::SetFacade
      end

      def new_facade(value)
        facade_class.new(coerce(value), self)
      end

      def restore_facade(raw_value)
        facade_class.new(raw_value, self)
      end

      #
      # We store sets internally as sets, and slap facades on them when the
      # user requests them.
      #
      def coerce(set)
        if set.is_a?(facade_class)
          set = set.set
        elsif item_type
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
      def coerce_out(set)
        if item_type
          facade_class.new(super, self)
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

      def self.possible_events
        super.merge(:on_set_updated => Event)
      end
    end
  end
end
