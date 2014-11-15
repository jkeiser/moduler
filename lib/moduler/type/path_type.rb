require 'moduler/path'

module Moduler
  module Type
    #
    # Represents a Pathname or String path with special +relative_to+
    # attribute to aid in DSL creation.
    #
    class PathType < Moduler::Type::BasicType
      # Whether to store (and return) as Pathname or String.  By default, calls Path.new.
      attribute :store_as, kind_of: Module, default: Path
      # If this is set, when the user specifies a relative path (or default), it
      # will be joined to this absolute path.  If the user specifies an absolute
      # path, `relative_to` does nothing.
      attribute :relative_to, Path#, store_as: lazy { store_as }
      # TODO allow attribute reopening, specialize from parent
      attribute :kind_of, Array[kind_of: [ Module ]], default: [ Pathname, String ]

      def path_class
        store_as == String ? Path : self.store_as
      end

      def coerce(value, context)
        if !value.nil?
          if value.is_a?(Enumerable)
            remaining_values = value.drop(1)
            value = value.first
          end
          value = path_class.new(value.to_s) if !value.is_a?(Pathname)
          if value.relative?
            if relative_to
              # TODO once relative_to can construct a lazy Pathname with the right class, this extra construct goes away
              value = path_class.new(relative_to.to_s) + value
            end
          end

          if remaining_values
            value = value.join(*remaining_values)
          end

          if value.is_a?(Path::Windows) || (Gem.win_platform? && [ Pathname, Path::Ruby ].include?(value.class))
            if value.to_s =~ /[^[:print:]]/
              msg = "Path '#{value}' contains non-printable characters. Check that backslashes are escaped with another backslash (e.g. C:\\\\Windows) in double-quoted strings."
              raise ValidationFailed.new([msg])
            end
          end

          value = value.to_s if store_as == String
        end
        super
      end

      def construct_raw(context, value, *paths)
        if !value.nil?
          value = path_class.new(value.to_s) if !value.is_a?(Pathname)
          value = value.join(*paths)
        end
        coerce(value, context)
      end
    end
  end
end
