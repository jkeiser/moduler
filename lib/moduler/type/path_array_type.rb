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

      def path_separator
        element_type.path_class <= Path::Base ? element_type.path_class.const_get(:PATH_SEPARATOR) : File::PATH_SEPARATOR
      end

      def coerce(value)
        if value.nil?
          return super(value)
        end
        # If the value is a single path string, split it by path separator
        if !value.is_a?(Array)
          value = value.to_s.split(path_separator)
        end
        relative_to = self.relative_to
        if relative_to
          if relative_to.empty?
            relative_to = nil
          else
            relative_to = relative_to.flat_map do |r|
              r.to_s.split(path_separator).map { |r| element_type.path_class.new(r) }
            end
          end
        end
        # Get the array of Pathnames and apply relative_to
        value = value.flat_map do |value|
          value = element_type.path_class.new(value.to_s) if !value.is_a?(Pathname)
          if value.relative? && element_type.relative_to
            value = element_type.relative_to + value
          end
          if relative_to && value.relative?
            value = relative_to.map { |relative_to| element_type.path_class.new(relative_to.to_s) + value }
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
