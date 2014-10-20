module Moduler
  module Type
    def self.inline(type=nil, options=nil, &block)
      Type.new(type, options, StructType).inline(&block)
    end

    def self.new(type=nil, options=nil, default_type_class=BasicType, &block)
      if !options
        if is_options?(type)
          options = type
          type = nil
          return default_type_class.new(options, &block)
        end
      end
      if !type
        return default_type_class.new(options, &block)
      end

      options ||= {}

      result = case type
      when Type
        type.specialize(options, &block)

      when ::Array
        if type.size == 0
          ArrayType.new(options, &block)
        elsif type.size == 1
          element_type = Type.new(type[0])
          ArrayType.new(options.merge(element_type: element_type), &block)
        end

      when ::Hash
        if type.size == 1
          key_type = Type.new(type.first[0])
          value_type = Type.new(type.first[1])
          HashType.new(options.merge(key_type: key_type, value_type: value_type), &block)
        end

      when ::Set
        if type.size == 0
          SetType.new(options, &block)
        elsif type.size == 1
          item_type = Type.new(type.first)
          SetType.new(options.merge(item_type: item_type), &block)
        end

      when Module
        if type.respond_to?(:type) && type.type.respond_to?(:specialize)
          type.type.specialize(options, &block)
        elsif type == Array
          ArrayType.new(options, &block)
        elsif type == Hash
          HashType.new(options, &block)
        elsif type == Set
          SetType.new(options, &block)
        elsif type == Struct
          StructType.new({ store_in_hash: true }.merge(options), &block)
        elsif type == Base::Boolean
          BasicType.new({ equal_to: [true,false] }.merge(options), &block)
        else
          BasicType.new({ kind_of: type }.merge(options), &block)
        end
      end

      if !result
        raise "Unknown type #{type}"
      end

      result
    end

    def self.is_options?(options)
      if options.respond_to?(:each_key)
        first = options.first
        if !first || first[0].is_a?(Symbol)
          return true
        end
      end
    end
  end
end

require 'moduler/type'
