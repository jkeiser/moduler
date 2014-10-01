module Moduler
  module Facade
    module Accessor
      module ValueAccess
        include Accessor

        def initialize(raw)
          @raw = raw
        end

        attr_reader :raw

        module DSL
          def define_value_access(guard)
            define_class(module_name(:ValueAccess, guard), guard) { include ValueAccess }.target
          end
        end
      end
    end
  end
end
