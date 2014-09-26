> Moduler  
  > ModuleCreator:
    - initialize(target, stream=true)
    - on_xxx(proc) do ... end (unlistens afterward)
    - target, stream?, closed?, close, on_close, on_closed, on_dsl_added
    - add_dsl, add_class_dsl, add_dsl_method, add_dsl_class_method, extend_dsl, include_dsl
  > Base
    > ModuleDSL:
      - module_creator
      - self.new(target, options, &block)
      - self.inject(target, options, &block)
      - specialize(target, options, &block)
      - extend(parent): add_dsl { include parent.created_module }; super
      - include(parent): add_module_dsl { include parent.created_module }; super
    > Struct: creates a struct with fields
      - attributes
      - add_attribute: field_type.specialize(:get_expression => "@{name}", :set...,:is_set...)
        add_dsl_method(:set -> 'def name=')
        add_dsl_method(:call -> 'def name')
    > Facade: creates a class that manages a raw value, allowing validation to interact with it.
      Intended to have a Validation class crossed with it.
      - get_expression, set_expression, is_set_expression
      > ArrayFacade: creates an array facade that manages an array
        - include_dsl ArrayFacade
        - [], []=, +, -, |, &, delete, add, <<, shift, unshift, pop, push, splice
        - element_type.catch_methods(:get, :set, :is_set), for 'yield, yield(value), yield(is_set)'
        - element_type.specialize(module_creator, :get_expression => "@{name}", :set..., :is_set...)
        - get: ArrayFacade[get_expression]
        - set: set_expression.is_a?(ArrayFacade) ? .get : expr
      > HashFacade: creates a hash facade on top of a raw hash
        - include_dsl HashFacade
        - [], []=, +, -, |, &, delete, add, <<, shift, unshift, pop, push, splice
        - element_type.catch_methods(:get, :set, :is_set), for 'yield, yield(value), yield(is_set)'
        - element_type.specialize(module_creator, :get_expression => "@{name}", :set..., :is_set...)
        - get: HashFacade[get_expression]
        - set: set_expression.is_a?(HashFacade) ? .get : expr
  > Type: < Struct
    > Attributes: a list of attributes.
      - Catches all attribute method texts
      - emits all methods verbatim (and assumes they are singular)
      > AllAttributes: *
      - get_expression, set_expression, is_set_expression
      - get: lazy (on_set), default (lazy -> set), coerce_out
      - set: lazy, (on_set=coerce,validate)
      - validate: cannot_be, equal_to, kind_of, regexes, respond_to, validate
      - get, set, validate; everything else verbatim (and single)
      > StandardAttributes: allow_lazy, coerce, coerce_out, on_set, on_call, on_added_to, on_removed_from, default, required, singular
      > ValidationAttributes: cannot_be, equal_to, kind_of, regexes, respond_to, validate
      > ArrayAttributes: on_array_update
      > HashAttributes: on_hash_update
  > Attribute: emit methods that can verify values.  May generate a module.
    > Attribute: attribute
    > AllowLazy: allow_lazy?
    > CannotBe:  validate
    > Coerce:    coerce
    > CoerceOut: coerce_out
    > Default:   coerce
    > EqualTo:   validate
    > KindOf:    validate
    > OnAddedTo: on_added_to
    > OnArrayUpdate: on_array_update
    > OnCall:    on_call
    > OnHashUpdate: on_hash_update
    > OnRemovedFrom: on_removed_from
    > OnSet:     on_set
    > TODO Readonly/Write only / etc.
    > Regexes:   validate
    > Required:  required?
    > RespondTo: validate
    > Type:      type
    > Validate:  validate

> Struct


> Facade
  > ArrayFacade
  > HashFacade
  > SetFacade

  Maybe they *create* modules that


  Type that provides base

  > ValueType
  - embed_get(value|NO_VALUE)

- Facade
  - ArrayFacade
  - HashFacade
    - [name]: type.value_type.embed_get(value[name])
    - [name=]: type.value_type.embed_get(value[name])

Created struct:
  - name <args>, &block:
    -
  - name=<value>

DSL:: (Types under DSL)
  <<StructDSL>>
  - attribute(name, type, value)
  - attributes, attributes=,

  <<TypeAttribute>>
  - type_attributes
  - type_attribute(name, TypeAttribute, options, &block)
  -
  <<StandardTypeAttributes>>
  - coerceCoerce


TypeClass
type
DslClass
dsl

StructType dsl:
dsl.name:
  Coerce(TypeVeneer.new, Coerce(<block>, StructFieldAccessor)
dsl.name=:

Facade
  - value
  ArrayFacade
  - element_type
  - [], etc.
  HashFacade
  - key_type
  - value_type
  - [], etc.

Accessor
  ItemAccessor
    - parent, index
    StructAccessor
  ValueAccessor
    - type, value

Type
  - accessor: ValueAccessor
  ArrayType
    - CoerceOut(ArrayVeneer) < CoerceOut(<block>) < ItemAccessor
    - item_accessor(index): ArrayItemAccessor(parent, type, value)
  EventType
  HashType
    - CoerceOut(HashFacade)
  StructType

Record:
  - get: type.get_field(attributes, name)
    - field_type.facade(type.accessor(self, type, name).get)
HashFacade:
  - get: type.facade(type.get_field.get)
ArrayFacade:
  - get: type.facade

.facade:
  -

AccessorClass
accessor:
  get
  set
  call
  type
  parent
