module Moduler
  module Lazy
    #
    # Get the value.  Assumed to be expensive.
    #
    def get
      raise NotImplementedError.new
    end
  end
end
