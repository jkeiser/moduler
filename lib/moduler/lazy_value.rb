module Moduler
  class LazyValue < Proc
    def initialize(cache=true, &block)
      super(&block)
      @cache = cache
    end

    attr_reader :cache
  end
end
