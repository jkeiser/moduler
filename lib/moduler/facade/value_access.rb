module Moduler
  module Facade
    module ValueAccess
      def initialize(raw)
        @raw = raw
      end

      attr_reader :raw

      module DSL
        def define_value_access(guard)
          define_class(module_name(:ValueAccess, guard)) do
            include ValueAccess
            include_guards guard
          end
        end
      end
    end
  end
end
