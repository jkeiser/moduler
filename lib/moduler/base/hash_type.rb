require 'moduler/base/type'
require 'moduler/facade/hash_facade'

module Moduler
  module Base
    class HashType < Type
      def raw_default
        defined?(@default) ? @default : {}
      end

      #
      # We store hashes internally as hashes, and slap facades on them when the
      # user requests them.
      #
      def coerce(value, context)
        if value.is_a?(Moduler::Facade::HashFacade)
          if value.type != self && (key_type || value_type)
            value = Facade::HashFacade.new({}, self).merge!(value).raw(context)
          else
            value = value.raw(context)
          end
        elsif !value.nil?
          if value.respond_to?(:to_hash)
            value = value.to_hash
          else
            raise ValidationFailed.new([ "Hash field must be set to a hash value: #{value.inspect} is not a hash value." ])
          end
          if key_type || value_type
            value = Facade::HashFacade.new({}, self, context).merge!(value).raw(context)
          end
        end
        super
      end

      #
      # When the user requests the hash, we give them a facade to protect the
      # values, assuming there is any index_type or element_type to protect.
      #
      def coerce_out(value, context)
        if value.is_a?(Value) || (value && (key_type || value_type))
          Facade::HashFacade.new(value, self, context)
        else
          value
        end
      end

      def new_facade(hash)
        Facade::HashFacade.new(to_raw(hash, context), self)
      end

      def clone_value(value)
        if !value
          value
        elsif key_type || value_type
          value.inject({}) do |r,(key,value)|
            key = key_type.clone_value(key) if key_type
            value = value_type.clone_value(value) if value_type
            r[key] = value
            r
          end
        else
          value.dup
        end
      end

      def emit(parent=nil, name=nil)
        key_type.emit(parent, name) if key_type
        value_type.emit(parent, name) if value_type
      end
    end
  end
end
