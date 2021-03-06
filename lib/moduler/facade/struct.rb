module Moduler
  module Facade
    module Struct
      def initialize(attributes=nil, is_raw=false, &block)
        set_attributes(attributes, is_raw, &block)
      end

      def set_attributes(attributes=nil, is_raw=false, &block)
        if attributes
          if is_raw
            attributes.each do |key, value|
              instance_variable_set("@#{key}", value)
            end
          else
            attributes.each do |key, value|
              setter = :"#{key}="
              if respond_to?(setter)
                public_send(setter, value)
              else
                public_send(key, value)
              end
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
        # TODO use overlays to make this a-nice.
        other = clone
        other.set_attributes(*args, &block)
        other
      end

      def ==(other)
        if other.class != self.class
          return false
        end
        self.class.type.attributes.each_pair do |name,type|
          var = :"@#{name}"
          # Don't pull defaults unless you have to
          var_defined = instance_variable_defined?(var)
          other_defined = other.instance_variable_defined?(var)
          next if !var_defined && !other_defined
          if type
            value = var_defined ? type.to_raw(instance_variable_get(var), self) : type.raw_default
            value = value.raw_read(self) if value.is_a?(Value)
          else
            value = instance_variable_get(var)
          end
          if type
            other_value = other_defined ? type.to_raw(other.instance_variable_get(var), self) : type.raw_default
            other_value = other_value.raw_read(self) if other_value.is_a?(Value)
          else
            other_value = other.instance_variable_get(var)
          end
          if value != other_value
            return false
          end
        end
        true
      end

      def to_hash(include_defaults = false)
        result = {}
        self.class.type.attributes.each_pair do |name,type|
          var = :"@#{name}"
          if instance_variable_defined?(var)
            result[name] = type.from_raw(instance_variable_get(var), self)
          elsif include_defaults
            result[name] = type.from_raw(type.raw_default, self)
          end
        end
        result
      end

      def is_set?(name)
        instance_variable_defined?("@#{name}")
      end

      def reset(name=nil)
        if name
          if instance_variable_defined?("@#{name}")
            result = remove_instance_variable("@#{name}")
            field_type = self.class.type.attributes[name]
            field_type ? field_type.from_raw(result, self) : result
          end
        else
          self.class.type.attributes.each_key do |name|
            remove_instance_variable("@#{name}") if instance_variable_defined?("@#{name}")
          end
        end
      end
    end
  end
end
