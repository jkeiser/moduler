require 'moduler/specializable'

module Moduler
  module Facade
    module Struct
      def initialize(*args, &block)
        dsl_eval(*args, &block)
      end

      def dsl_eval(options=nil, &block)
        if options
          options.each do |key, value|
            if respond_to?(:"#{key}=")
              public_send(:"#{key}=", value)
            else
              public_send(key, value)
            end
          end
        end
        instance_eval(&block) if block
      end

      def clone
        other = self.dup
        self.class.type.attributes.each_pair do |key,type|
          var = :"@#{key}"
          if other.instance_variable_defined?(var)
            value = type.clone_value(other.instance_variable_get(var))
            other.instance_variable_set(var, value)
          end
        end
        other
      end

      def specialize(*args, &block)
        other = clone
        other.dsl_eval(*args, &block)
        other
      end

      def ==(other)
        if other.class != self.class
          return false
        end
        self.class.type.attributes.each_pair do |name,type|
          var = :"@#{name}"
          # Don't pull defaults unless you have to
          next if !instance_variable_defined?(var) &&
                  !other.instance_variable_defined?(var)

          value = type.raw_value(instance_variable_get(var)) do |v|
            instance_variable_set(var, v)
          end
          other_value = type.raw_value(other.instance_variable_get(var)) do |v|
            other.instance_variable_set(var, v)
          end
          if value != other_value
            return false
          end
        end
        true
      end

      def to_hash
        result = {}
        self.class.type.attributes.each_pair do |name,type|
          var = :"@#{name}"
          if instance_variable_defined?(var)
            result[name] = type.raw_value(instance_variable_get(var)) do |v|
              instance_variable_set(var, v)
            end
          end
        end
        result
      end

      def is_set?(name)
        instance_variable_defined?("@#{name}")
      end

      def reset(name)
        remove_instance_variable("@#{name}")
      end
    end
  end
end
