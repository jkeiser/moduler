#
# Simple, extensible and powerful DSL for creating validated, highly structured
# "struct" classes in Ruby.
#
module Moduler
  #
  # Run the Moduler DSL against the current module or class.
  #
  # The module/class is detected based on the block's self (the place the
  # block was created).
  #
  def self.inline(*args, &block)
    if !block
      raise "Moduler.inline must be passed a block!"
    end
    type = Moduler::TypeDSL.type_system.struct_type.specialize(*args, &block)
    type.facade_class = block.binding.eval('self')
  end

  #
  # Create a struct with the given name in the current namespace.
  #
  def self.struct(name, *args, &block)
    if !block
      raise "Moduler.inline must be passed a block!"
    end

    parent = block.binding.eval('self')
    if !parent.is_a?(Module)
      parent = parent.class
    end

    type = Moduler::TypeDSL.type_system.struct_type.specialize(*args, &block)

    # This is the only method of creating a class/module that preserves the
    # name *even* when it's being created inside of a class with no name
    # (like a metaclass).
    child = eval "class parent::#{name}; self; end"
    type.facade_class = child
  end

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

require 'moduler/type_dsl'
