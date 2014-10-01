module Moduler
  module Facade
    class RawFacade
      include Facade

      module DSL
        def raw_facade
          RawFacade
        end
      end
    end
  end
end
