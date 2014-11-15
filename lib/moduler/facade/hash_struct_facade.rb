require 'moduler/facade'

module Moduler
  module Facade
    module HashStructFacade
      include Facade

      def initialize(raw={}, context=nil, is_raw=false, &block)
        if is_raw
          super(raw, nil, context)
          instance_eval(&block) if block
        else
          super({}, nil, context)
          set_attributes(raw, is_raw, &block)
        end
      end

      def type
        self.class.type
      end

      def set_attributes(attributes=nil, is_raw=false, &block)
        if attributes
          if is_raw
            raw_read.merge!(attributes)
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
          if raw_read.has_key?(key)
            other.raw_read(context)[key] = type.clone_value(raw_read(context)[key])
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
        if other.class == self.class
          self.class.type.attributes.each_pair do |key,type|
            # Don't pull defaults unless you have to
            var_defined = raw_read.has_key?(key)
            other_defined = other.raw_read(context).has_key?(key)
            next if !var_defined && !other_defined

            value = var_defined ? type.to_raw(raw_read[key], context) : type.raw_default
            value = value.raw_read(context) if value.is_a?(Value)
            other_value = other_defined ? type.to_raw(other.raw_read(context)[key], context) : type.raw_default
            other_value = other_value.raw_read(context) if other_value.is_a?(Value)
            if value != other_value
              return false
            end
          end
        elsif other.respond_to?(:to_hash)
          to_hash == other.to_hash
        end
      end

      def to_hash(include_defaults = false)
        if include_defaults
          result = {}
          self.class.type.attributes.each_pair do |key,type|
            result[key] = type.from_raw(raw_read.has_key?(key) ? raw_read[key] : type.raw_default, context)
          end
          result
        else
          raw_read
        end
      end

      def is_set?(name)
        raw_read.has_key?(name)
      end

      def reset(name=nil)
        if name
          if raw_read.has_key?(name)
            result = raw.delete(name)
            field_type = self.class.type.attributes[name]
            field_type ? field_type.from_raw(result, context) : result
          end
        elsif raw_read.size > 0
          raw.clear
        end
      end

      def has_key?(name)
        raw_read.has_key?(name) || self.type.attributes.has_key?(name)
      end

      def [](name)
        if type.attributes.has_key?(name)

          attribute_type = type.attributes[name]

          if attribute_type
            if raw_read.has_key?(name)
              attribute_type.from_raw(raw_read[name], context)

            else
              # We don't have a key; return the default.

              # We don't set defaults into the struct right away; only if the
              # user tries to write to them.  Frozen defaults (like an int)
              # we don't store at all.
              raw_default = attribute_type.raw_default
              if raw_default.frozen?
                raw_value = raw_default
              else
                raw_value = Value::Default.new(raw_default) do
                  if raw_read.has_key?(name)
                    raise "#{name} was defined by someone else: race!"
                  else
                    raw[name] = raw_default
                  end
                end
              end

              attribute_type.from_raw(raw_value, context)
            end
          else
            raw_read[name]
          end
        else
          raise "Invalid key #{}"
        end
      end

      def []=(name, value)
        if type.attributes.has_key?(name)
          attribute_type = type.attributes[name]
          raw[name] = attribute_type ? attribute_type.to_raw(value, context) : value
        else
          raw[name] = value
        end
      end
    end
  end
end
