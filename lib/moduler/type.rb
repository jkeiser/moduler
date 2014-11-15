require 'moduler/base/type'
require 'moduler/base/boolean'
require 'moduler/value'
require 'moduler/value/lazy'
require 'moduler/type/type_constructor'
require 'moduler/type/type_validator'

module Moduler
  module Type
    Boolean = Moduler::Base::Boolean

    def lazy(cache=true, &block)
      Moduler::Value::Lazy.new(cache, nil, &block)
    end

    require 'moduler/base/inline_struct'
    extend Moduler::Base::InlineStruct
    require 'moduler/type/type_struct'
    extend TypeStruct
    require 'moduler/type/basic_type'
    type.default_class = BasicType

    attr_accessor :nullable, :cannot_be, :equal_to, :kind_of, :regexes, :respond_to, :validators, :required

    require 'moduler/type/array_type'

    attribute :kind_of,     Array[kind_of: [ Module ]]
    attribute :equal_to,    Array
    attribute :nullable,    Boolean, :default => true
    attribute :regexes,     Array[kind_of: [ Regexp, String ]]
    attribute :cannot_be,   Array[Symbol]
    attribute :respond_to,  Array[kind_of: [ Symbol, String ]]
    attribute :validators,  Array[Proc]
    attribute :required,    Boolean
  end
end

require 'moduler/type/hash_type'
require 'moduler/type/array_type'
require 'moduler/type/set_type'
require 'moduler/type/struct_type'
require 'moduler/type/path_type'
require 'moduler/type/path_array_type'
