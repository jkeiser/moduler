module Moduler
  module Attributable
    def initialize(*args, &block)
      case args[0]
      when Attributable
        if @hash
          @hash.merge!(args.shift.instance_eval { @hash })
        else
          @hash = args.shift.instance_eval { @hash }
        end
      else
        @hash ||= {}
      end
      super(*args, &block)
    end
  end
end
