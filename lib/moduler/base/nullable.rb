module Moduler
  module Base
    # A marker for a nullable type.  "Nullable[Type]" means "this type, or nil."
    class Nullable
      def self.[](type)
        new(type)
      end
      def initialize(type)
        @type = type
      end
      attr_reader :type
    end
  end
end
