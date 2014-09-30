require 'facade'

module Moduler
  module Core
    module Facade
      #
      # Slaps an array interface on top of the raw value (which subclasses can
      # override).
      #
      module SetFacade
        include Facade
        include Enumerable
        moduler.inline do
          forward :raw, :size
          forward :raw, :include?, :member?
          forward :raw, :add, :<<, :delete
          forward :raw, :each
        end
      end

      def define_set_facade(name, item_facade = nil)
        moduler.define_module(name) do |moduler|
          include_module SetFacade

          if item_facade
            def include?(item)
              item = item_facade.coerce(item)
              raw.include?(item)
            end
            def member?(item)
              item = item_facade.coerce(item)
              raw.member?(item)
            end
            def add(item)
              item = item_facade.coerce(item)
              raw.add(item
            end
            def <<(item)
              item = item_facade.coerce(item)
              raw << item
            end
            def delete(item)
              item = item_facade.coerce(item)
              raw.delete(item)
            end
            def each
              raw.each { |item| yield item_facade.coerce(item) }
            end
          end
        end
      end
    end
  end
end
