require 'moduler/base/type'

module Moduler
  module Base
    class ValidatingType < Type
      attribute :default
      attribute :start_with do
        call_proc do |*args, &block|
          if args.size == 0 && !block && !@hash[:start_with]
            nil
          else
            NOT_HANDLED
          end
        end
      end



            #
            # start_with is used while constructing, so we need to short-circuit
            # the "get" and make sure that it
            # If the value is not set, and the user does .your_field 'a', 'b' ...
            # this value will be the "start value" for specialize('a', 'b', ...)
            #
            Type.emit_attribute self, :start_with #do

            Type.emit_attribute self, :reopen_on_call#, :equal_to => [ true, false ], :default => false

    end
  end
end
