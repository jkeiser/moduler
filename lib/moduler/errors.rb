module Moduler
  class ModulerError < StandardError
  end
  class ModuleClosedError < ModulerError
    def initialize(m)
      @module = m
    end
    attr_reader :module
  end

  class ModulerFacadeError < ModulerError
    def initialize(facade, message=nil)
      @facade = facade
      super(facade, message)
    end

    attr_reader :facade
  end

  #
  # Thrown when attempting to access a Struct attribute that is undefined
  # via key methods like [] or []=
  #
  class NoSuchFieldError < ModulerFacadeError
    def initialize(facade, attribute_name, message=nil)
      @attribute_name = attribute_name
      super(facade, build_message(prefix, postfix))
    end

    attr_reader :attribute_name

    def build_message
      super("No such attribute #{attribute_name}")
    end
  end

  class ValidationFailed < ModulerError
    def initialize(failures, message=nil)
      @failures = failures
      message = "Validation failed: #{failures.map { |f| f.is_a?(Hash) ? f[:message] : f }.join("\n")}"
      super(message)
    end

    attr_reader :failures
  end
end
