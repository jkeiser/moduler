> Moduler
  > Specializable
  > Core: the core DSL that creates modules and facades
    > Basic: simple DSL to create modules
    > DSL: module DSL with attribute and facade support
    > Facade: the base class for facades (classes which act like standard Ruby
      classes but which let you do events, transformations and validations on
      values)
      > ArrayFacade, HashFacade, SetFacade, StructFacade
    > Attributes: basic syntax for attributes.
    > Events, Transformers, Validators: facades for standard attributes
  > DSL: the type-based DSL that stores type information and puts a nice syntax on it
    > Type, Struct, Array, Hash, Set
  > Event
