module Moduler
  module Attributable
    def initialize(*args, &block)
      @hash ||= {}
      if args[0].is_a?(Attributable)
        @hash.merge!(args.shift.instance_eval { @hash })
      end
      super(*args, &block)
    end
  end
end
