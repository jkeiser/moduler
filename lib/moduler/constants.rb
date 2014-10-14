module Moduler
  #
  # Constant indicating a lack of a value (as opposed to +nil+), so that methods
  # know when to fill in defaults.
  #
  NO_VALUE = begin
    obj = Object.new
    class<<obj
      def to_s
        "NO_VALUE"
      end
      def inspect
        "NO_VALUE#{super}"
      end
    end
    obj
  end

  #
  # Constant indicating a call or event was not handled, so that the caller can
  # take special action.
  #
  NOT_HANDLED = begin
    obj = Object.new
    class<<obj
      def to_s
        "NOT_HANDLED"
      end
      def inspect
        "NOT_HANDLED#{super}"
      end
    end
    obj
  end

  #
  # Constant used for methods that want to find out whether they passed a value
  # or not.  This should *never* be passed to another method (while the other
  # two constant may).
  #
  NOT_PASSED = begin
    obj = Object.new
    class<<obj
      def to_s
        "NOT_PASSED"
      end
      def inspect
        "NOT_PASSED#{super}"
      end
    end
    obj
  end
end
