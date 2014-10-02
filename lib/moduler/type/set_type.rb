require 'moduler/type'

module Moduler
  class Type
    class SetType < Type
      attr_accessor :item_type

      def facade_class
        SetFacade
      end

      def coerce(set)
        if set.is_a?(facade_class)
          set = set.raw
        end
        super(set)
      end

      def coerce_out(set)
        facade_class.new(super, self)
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
