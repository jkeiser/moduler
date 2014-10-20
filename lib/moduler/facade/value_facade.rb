require 'moduler/facade'
require 'moduler/lazy'

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
        if @raw.is_a?(Lazy)
          @raw.get_for_read
        else
          @raw
        end
      end

      #
      # The raw value, for write purposes
      #
      def raw_write
        if @raw.is_a?(Lazy)
          @raw.get
        else
          @raw
        end
      end
    end
  end
end
