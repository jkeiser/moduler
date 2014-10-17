module Moduler
  module Lazy
    #
    # Get the value.  Assumed to be expensive.
    #
    def get
      raise NotImplementedError.new
    end

    #
    # Get the value for read purposes.  Used by some APIs to do less work until
    # and unless you actually want a writeable value.
    #
    def get_for_read
      get
    end
  end
end
