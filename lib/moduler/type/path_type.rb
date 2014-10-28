require 'moduler/path'

module Moduler
  module Type
    #
    # Represents a Pathname or String path with special +relative_to+
    # attribute to aid in DSL creation.
    #
    class PathType < Moduler::Type::BasicType
      # If this is set, when the user specifies a relative path (or default), it
      # will be joined to this absolute path.  If the user specifies an absolute
      # path, `relative_to` does nothing.
      attribute :relative_to, Path
      # TODO allow attribute reopening, specialize from parent
      attribute :kind_of, Array[kind_of: [ Module ]], default: [ Pathname, String ]
      # Whether to store (and return) as Pathname or String.  Defaults to Pathname.
      attribute :store_as, equal_to: [ Pathname, String ], default: Pathname, nullable: false

      def coerce(value)
        if !value.nil?
          value = Path.new(value.to_s) if !value.is_a?(Pathname)
          if value.relative? && relative_to
            value = relative_to + value
          end
          value = value.to_s if store_as == String
        end
        super(value)
      end

      def construct_raw(value, *paths)
        if !value.nil?
          value = Path.new(value.to_s) if !value.is_a?(Pathname)
          value = value.join(*paths)
        end
        coerce(value)
      end
    end
  end
end
