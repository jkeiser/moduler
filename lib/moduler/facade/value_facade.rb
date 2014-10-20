require 'moduler/facade'

module Moduler
  module Facade
    class ValueFacade
      include Facade

      def initialize(raw, type)
        @raw = raw
        @type = type
      end

      attr_reader :type

      #
      # The raw value, for read purposes.
      #
      def raw
        if @raw.is_a?(Lazy::Value)
          if @raw.is_a?(Lazy::ForReadValue)
            @raw.get_for_read
          else
            @raw.get
          end
        else
          @raw
        end
      end

      #
      # The raw value, for write purposes
      #
      def raw_write
        if @raw.is_a?(Lazy::Value)
          @raw.get
        else
          @raw
        end
      end
    end
  end
end
