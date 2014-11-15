module Moduler
  module Value
    #
    # Get the value, raw.  Assumed to be expensive.
    #
    def raw(context)
      raise NotImplementedError.new('raw')
    end

    #
    # Get the value, raw.  Assumed to be expensive.
    #
    def raw_read(context)
      raw(context)
    end

    #
    # Get the value, after coercion.  Assumed to be expensive.
    #
    def get(context)
      raw(context)
    end

    #
    # Call to make sure it is safe to write to the given value
    #
    def ensure_writeable(context)
    end

    #
    # Returns whether this value is writeable or not
    #
    def writeable?
      true
    end

    #
    # The context in which the value was retrieved (and in which any lazy values
    # will be evaluated)
    #
    def context
      nil
    end
  end
end
