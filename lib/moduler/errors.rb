module Moduler
  class ModulerError < StandardError
  end
  class ModuleClosedError < ModulerError
    def initialize(m)
      @module = m
    end
    attr_reader :module
  end
end
