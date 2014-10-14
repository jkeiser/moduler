require 'moduler/scope'

module Moduler
  #
  # A Specializable thing.
  #
  module Specializable
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
      case self
      when Class
        other = self.class.new(self)
      else
        other = clone
      end

      other.dsl_eval(*args, &block)
      other
    end
  end
end
