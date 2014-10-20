module Moduler
  module Facade
    module HashStruct
      def initialize(attributes=nil, is_raw=false, &block)
        if is_raw
          super(attributes, nil)
          instance_eval(&block) if block
        else
          super({}, nil)
          set_attributes(attributes, is_raw, &block)
        end
      end

      def type
        self.class.type
      end

      def set_attributes(attributes=nil, is_raw=false, &block)
        if attributes
          if is_raw
            raw.merge!(attributes)
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
          if raw.has_key?(key)
            other.raw[key] = type.clone_value(raw[key])
          end
        end
        other
      end

      def specialize(*args, &block)
        other = clone
        other.set_attributes(*args, &block)
        other
      end

      def ==(other)
        if other.class != self.class
          return false
        end
        self.class.type.attributes.each_pair do |key,type|
          # Don't pull defaults unless you have to
          var_defined = raw.has_key?(key)
          other_defined = other.raw.has_key?(key)
          next if !var_defined && !other_defined

          value = var_defined ? type.to_raw(raw[key]) : type.raw_default
          value = value.get_for_read if value.is_a?(Lazy)
          other_value = other_defined ? type.to_raw(other.raw[key]) : type.raw_default
          other_value = other_value.get_for_read if other_value.is_a?(Lazy)
          if value != other_value
            return false
          end
        end
        true
      end

      def to_hash(include_defaults = false)
        if include_defaults
          result = {}
          self.class.type.attributes.each_pair do |key,type|
            result[key] = type.from_raw(raw.has_key?(key) ? raw[key] : type.raw_default)
          end
          result
        else
          raw
        end
      end

      def is_set?(name)
        raw.has_key?(name)
      end

      def reset(name=nil)
        if name
          if raw.has_key?(name)
            result = raw_write.delete(name)
            field_type = self.class.type.attributes[name]
            field_type ? field_type.from_raw(result) : result
          end
        elsif raw.size > 0
          raw_write.clear
        end
      end
    end
  end
end
