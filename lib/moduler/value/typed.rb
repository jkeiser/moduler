require 'moduler/value/basic'

module Moduler
  module Value
    module Typed
      include Value::Basic

      def initialize(raw, type)
        super(raw)
        @type = type
      end

      attr_reader :type

      def get(context)
        type.from_raw(raw(context), context)
      end
    end
  end
end
