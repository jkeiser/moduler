require 'moduler/value'

module Moduler
  module Value
    module Basic
      include Value

      def initialize(raw)
        @raw = raw
      end

      def raw(context)
        ensure_writeable(context)
        if @raw.is_a?(Value)
          @raw.raw(context)
        else
          @raw
        end
      end

      def raw_read(context)
        if @raw.is_a?(Value)
          @raw.raw_read(context)
        else
          @raw
        end
      end

      def ensure_writeable(context)
        if @raw.is_a?(Value)
          @raw.ensure_writeable(context)
        end
      end

      def writeable?
        @raw.is_a?(Value) ? @raw.writeable? : true
      end
    end
  end
end
