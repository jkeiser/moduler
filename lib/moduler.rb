require 'moduler/constants'

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
    Moduler::TypeDSL.inline(*args, &block)
  end

  #
  # Create a struct with the given name in the current namespace.
  #
  def self.struct(name, *args, &block)
    Moduler::TypeDSL.struct(name, *args, &block)
  end
end

require 'moduler/type_dsl'
