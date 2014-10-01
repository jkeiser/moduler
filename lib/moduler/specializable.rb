module Moduler
  #
  # A Specializable thing.
  #
  module Specializable
    def initialize(base=nil, options={}, &block)
      # If the user passed a hash for base, we assume they passed just options
      # and no base.
      if base.is_a?(Hash) && options == {}
        base, options = nil, base
      end
      if base.is_a?(Class) && self.is_a?(Class)
        super(base)
      else
        super()
        extend(base) if base
      end
      dsl_eval(options, &block)
    end

    def dsl_eval(options={}, &block)
      options.each do |key, value|
        if respond_to?("#{key}=")
          public_send("#{key}=", value)
        else
          public_send(key, value)
        end
      end
      instance_eval(&block) if block
    end

    def specialize(options={}, &block)
      self.class.new(self, options, &block)
    end
  end
end
