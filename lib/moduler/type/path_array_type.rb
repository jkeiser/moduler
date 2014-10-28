require 'pathname'
require 'moduler/path'
require 'moduler/type/path_type'

# TODO Make a real Path class to replace the Chef PathHelper stuff
module Moduler
  module Type
    #
    # Represents an array of paths, with support for path list strings such
    # as +ENV['PATH']+, and a +relative_to+ array so that you can make one
    # path list relative to another path list.
    #
    class PathArrayType < Moduler::Type::ArrayType
      attribute :element_type, PathType
      attribute :relative_to, Array[Path]

      def coerce(value)
        if value.nil?
          return super(value)
        end
        # If the value is a single path string, split it by path separator
        if !value.is_a?(Array)
          value = value.to_s.split(File::PATH_SEPARATOR)
        end
        # Get the array of Pathnames and apply relative_to
        value = value.flat_map do |value|
          value = Path.new(value.to_s) if !value.is_a?(Pathname)
          if value.relative? && element_type.relative_to
            value = element_type.relative_to + value
          end
          if value.relative? && relative_to && !relative_to.empty?
            value = relative_to.map { |relative_to| relative_to + value }
          end
          value
        end
        super(value)
      end

      def construct_raw(*args)
        if args.size == 1 && args[0].nil?
          super
        else
          args.flat_map do |arg|
            coerce(arg)
          end
        end
      end
    end
  end
end
