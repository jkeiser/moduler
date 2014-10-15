require 'moduler/base/type'
require 'moduler/base/boolean'
require 'moduler/base/value_context'
require 'moduler/lazy_value'
require 'moduler/type/type_constructor'
require 'moduler/type/type_validator'

module Moduler
  module Type
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

    require 'moduler/base/inline_struct'
    extend Moduler::Base::InlineStruct
    require 'moduler/type/type_struct'
    extend TypeStruct
    require 'moduler/type/basic_type'
    type.default_class = BasicType

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
