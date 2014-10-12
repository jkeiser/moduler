require 'moduler/event'
require 'moduler/facade/set_facade'
require 'set'

module Moduler
  module Base
    module SetType
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
      # def facade_class
      #   Moduler::Facade::SetFacade
      # end
      #
      # def new_facade(value)
      #   facade_class.new(coerce(value), self)
      # end
      #
      # def restore_facade(raw_value)
      #   facade_class.new(raw_value, self)
      # end

      #
      # We store sets internally as sets, and slap facades on them when the
      # user requests them.
      #
      def coerce(set)
        if set.is_a?(facade_class)
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
        set = coerce_out_base(set, &cache_proc)
        if set == NO_VALUE
          set = Set.new
          cache_proc.call(set)
        end

        if item_type
          facade_class.new(set, self)
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

    #
    # Handle singular form:
    # address :street => ... do ... end
    # zipcode 80917
    #
    def emit_attribute(target, name)
      super
      if @hash[:singular]
        type = self
        target.send(:define_method, @hash[:singular]) do |*args, &block|
          key = type.coerce_key(args.shift)
          context = SetAddContext.new(@hash, name)
          if element_type
            element_type.call(context, *args, &block)
          else
            # Create a type from the empty type
            type_system.base_type.call(context, *args, &block)
          end
        end
      end
    end

    class SetAddContext
      def initialize(attributes, name)
        @attributes = attributes
        @name = name
      end

      def get
        NO_VALUE
      end

      def set(value)
        @attributes[@name] ||= Set.new
        @attributes[@name] << value
      end
    end
  end
end
