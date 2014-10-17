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
  > DSL: the type-based DSL that stores type information and puts a nice syntax on facades
    > Type, Struct, Array, Hash, Set
  > Event

Facades
-------
Facades are classes that mitigate how users will *use* a raw value.  They are designed to be layered on top of a value, and provide normal access semantics, as well as class-level methods so that the type system can assist with things like default values:

- get(accessor) - get the value from the accessor
- set(accessor, value) - set the value of the accessor
- call(accessor, *args, &block) - "call" the value.
- coerce_in(raw) - transform or validate the value on the way in.  This can be used without the associated cost of creating an accessor.
- coerce_out(raw) - transform or validate the value on the way out.
- new(accessor) - create a new instance of the facade, using the accessor as input.  Most classes will simply grab the raw value from the accessor; some will preserve the accessor itself.

Guards
------
Guards are objects with static methods to validate or transform values as they head into or out of the system.

They provide these methods:
- coerce_in(raw) - validate or transform the value on its way in
- coerce_out(raw) - validate or transform the value on its way out

Accessors
---------
Accessors provide access to a raw value in such a way that it can be set or got.

- raw: access to the raw value for superclasses

Creating Facades: Composition
=============================

In general, you will create facade classes with four classes in your hierarchy:
1. Facade: the top level base class.  Handles standard get/set/call operations.
2. User DSL: HashFacade/*Facade: specific types of facade that add array, hash,
   set or struct semantics to your facade.
3. Guard: a class that handles standard behavior for your type system.  The most
   basic one, Moduler::Guard, handles 1-n coercers/validators, default values,
   and lazy values.
4. Accessor: the actual physical storage for the value.  This can be as simple
   as an instance variable, or as complicated as a path or URL.

MyClass.new(property: value, property: value) do
  <instance dsl>
  property value
  property value
end

The input hash acts just like

These classes are meant to

Guards
-------
The heart of the type system--the thing that really gets types working--is *facades*.  A Guard is a module that handles events, handles complex logic (like defaults and lazy values), validates, or transforms a raw value.  The module expects to be plugged into a class with the methods:

> Things Guard expects to exist:
> [`raw`]
> Gets the current raw value.
> [`raw=`]
> Sets the current raw value.
> [`has_raw?`]
> Returns true or false depending on whether the current raw value is defined.

A Guard implements one or more of the following methods:

> [`get`]
> Gets the current value for the user.
> [`set(value)`]
> Sets the current value from input from the user.
> [`call(*args, &block)`]
> Handles what happens when you *call* the value as a method.
> [`self.coerce(value)`]
> Transforms a value from the user into a raw, storable one.
> [`self.coerce_out(value)`]
> Transforms the raw value into one we want to give to the user.

By default, the top-level Guard does no filtering, and implements these thus:

> ```ruby
> module Guard
>   def get
>     coerce_out(raw)
>   end
>   def set(value)
>     raw = coerce(value)
>   end
>   def call(value=NOT_PASSED, &block)
>     if block
>       set(block)
>     elsif value == NOT_PASSED
>       get
>     else
>       set(value)
>     end
>   end
>   def self.coerce(value)
>     value
>   end
>   def self.coerce_out(value)
>     value
>   end
> emd
> ```

### Validators

When you add a Validator into the stack like `:kind_of => [String|Symbol]`, it generally looks something like this:

> ```ruby
> module KindOfValidator
>   def self.coerce_out(value)
>     if value.is_a?(String) || value.is_a?(Symbol)
>       super(value)
>     else
>       raise ValidationError.new("Value was not a String or Symbol.")
>     end
>   end
> end
> ```

### Default Values

When you add a default value into the stack, it looks like this:

> ```ruby
> module MyDefaultValue
>   def get
>     if has_raw?
>       super
>     else
>       coerce_out(default)
>     end
>   end
> end
> ```

### Lazy Values

When you add the ability for the user to do lazy values into the mix, you generally
add a LazyGuard at the top (just before Guard), doing:

> ```ruby
> module LazyValueGuard
>   def set(value)
>     if value.is_a?(Lazy)
>       raw = value # Set without coercion; the coercion will happen on get.
>     else
>       raw = coerce(value)
>     end
>   end
>   def get
>     if raw.is_a?(Lazy)
>       coerce_out(coerce(raw))
>     else
>       coerce_out(raw)
>     end
>   end
> end
> ```

Note the lack of unnecessary methods: only methods actually used in the facade
are implemented.  This gets rid of some performance issues typically involved
with this sort of chaining.

### Actual Value Guarding

When it comes down to the end, a Value class guards the value with an implementation like this:

```ruby
class MyValue
  include Facade
  include KindOfValidator
  include MyDefaultValue
  include LazyValueGuard

  attr_accessor :my_hash
  attr_accessor :key
  def raw
    my_hash[key]
  end
  def raw=(value)
    my_hash[key] = value
  end
  def has_raw?
    my_hash.has_key?(key)
  end
end
```

Facades
-------

Facades are classes that guard access to compound objects, such as arrays, hashes
and other instances.

### HashFacade

Constructing a HashFacade looks like this:

```ruby
HashFacade.new(my_hash, key_facade, value_facade)
```

HashFacade will provide all the normal accessors for a hash, but will handle coercion and validation so that hash values don't become corrupted.
