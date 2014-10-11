require 'moduler/scope'

module Moduler
  #
  # A Specializable thing.
  #
  module Specializable
    def initialize(*args, &block)
      case args[0]
      when Class
        super(args.shift)
      when Moduler::Scope
        Scope.bring_into_scope(args.shift)
        super()
      else
        super()
      end
      dsl_eval(*args)
      instance_eval(&block) if block
    end

    def dsl_eval(options={}, &block)
      options.each do |key, value|
        if respond_to?(:"#{key}=")
          public_send(:"#{key}=", value)
        else
          public_send(key, value)
        end
      end
      instance_eval(&block) if block
    end

    def specialize(*args, &block)
      self.class.new(self, *args, &block)
    end
  end
end
