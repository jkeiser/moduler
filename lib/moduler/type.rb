require 'moduler/base/type'
require 'moduler/base/boolean'
require 'moduler/base/value_context'
require 'moduler/lazy_value'

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
        if type.size == 0
          HashType.new(options, &block)
        elsif type.size == 1
          key_type = Type.new(type.first[0])
          value_type = Type.new(type.first[1])
          HashType.new(options.merge(key_type: key_type, value_type: value_type), &block)
        end

      when ::Set
        if type.size == 0
          SetType.new(options, &block)
        elsif type.size == 1
          item_type = Type.new(type[0].key)
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
        if first && first[0].is_a?(Symbol)
          return true
        end
      end
    end

    Boolean = Moduler::Base::Boolean

    def lazy(cache=true, &block)
      Moduler::LazyValue.new(cache, &block)
    end
    def specialize(type=nil, options=nil, &block)
      if !options && Type.is_options?(type)
        options = type
        type = nil
      end
      if options
        options.merge!(supertype: self)
      else
        options = { supertype: self }
      end
      Type.new(type, options, self.class, &block)
    end

    require 'moduler/base/struct_type'
    require 'moduler/type/basic_type'

    @type = Base::StructType.new default_class: BasicType

    require 'moduler/base/inline_struct'
    extend Moduler::Base::InlineStruct
    require 'moduler/type/type_struct'
    extend TypeStruct

    attribute :equal_to
    attribute :kind_of

    require 'moduler/type/array_type'

    attribute :equal_to,   Array
    attribute :kind_of,    Array[Module]
    attribute :nullable,   Boolean
    attribute :regexes,    Array[kind_of: [ Regexp, String ]]
    attribute :cannot_be,  Array[Symbol]
    attribute :respond_to, Array[Symbol]
    attribute :validators, Array[Proc]
    attribute :required,   Boolean
  end
end

require 'moduler/type/hash_type'
require 'moduler/type/array_type'
require 'moduler/type/set_type'
require 'moduler/type/struct_type'
