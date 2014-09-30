module Moduler
  module DSL
    module Base
      #
      # Provides the basic functionality for creating modules, particularly
      # paying attention to class hierarchy (if this DSL includes or extends
      # another DSL moduler, we hook up the modules they are creating).
      #

      #  (and hides many of them inside
      # module_moduler for a smaller)
      #
      module TypeDSL
        include Moduler::Base::Specializable

        attr_accessor :moduler

        #
        # When done with the DSL moduler, close out the module to prevent it from
        # being added to and to clean up data.
        #
        def close
          @value_class ||= Moduler::moduler::Value::Proxy
          @transformer ||= Moduler::moduler::Transformer
          moduler.close
          moduler = nil
        end

        #
        # Get the instantiable class associated with this type, which can
        # *protect* the raw value.  It must have +initialize(value)+ and +get+
        # methods.
        #
        attr_reader :value_class

        #
        # Get the transformer module associated with this type so that *others*
        # can store the raw value.
        #
        attr_reader :transformer

        #
        # When we extend another DSL, we make sure the created module includes
        # the created DSL as well.
        #
        def extend(dsl)
          super
          if dsl.is_a?(ModuleDSL)
            module_moduler.include_dsl(dsl.module_moduler.target)
          end
        end
      end
    end
  end
end
