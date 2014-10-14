Principles
----------

It should:
- Be as close to Ruby as possible.  `def blah` should always make you a method in the thing you are evaluating.  `self` should never be a proxy.
- Feel like a type system.  Users should be able to use it to *model*, and then let the system handle *generating* the result
- Contain as few abstractions as possible.  We are not writing a new language here, we are writing extensible class generators.  It must be comprehensible.
- Be extensible.  People should be able to make new generators, and new type validators/coercers, without much trouble.
- Be debuggable.  Metaprogramming and code generation can be hard to debug if done wrong.  When you generate code for an attribute, the attribute name must appear in backtraces.  method_missing should never show up in backtraces (confusing as hell).  When generated code fails, you must be able to find the code easily and quickly from the stack trace.

Abstractions
------------

### Type

Types represent and manage strongly typed things, *and* are used to generate classes.  They are able to transform values *into* a "raw" system and *out* of it.

- `coerce`:
- `coerce_out`:

The base types provided are:
- `Type`: The root of the type system.  Serves as a marker for the base methods.
- `StructType`: A type that has attributes and can build structs.
- `HashType`: Represents a hash value.

#### StructType

The only type that presently supports direct class emission is *struct*.  It implements `Emittable` and has these properties:

- `target`:
- `emit`: emit to the target class or module

#### TypeDSL

This is the type

### Lazy

The Accessor system wraps accesses around values.  Facades are special sorts of accessor that .  Lazy values are accessors that don't unwrap until you ask for them (and who may cache their value).

- `get`: get the value.  If for_read is true, it indicates to the wrapper that it does not need to cache or set the value.
- `writeable`: whether the value returned from `get` can be written to.  Set to `true` to flip this.  Not all types implement setting to `true`.
- `cacheable`: whether the caller can cache the value.  If `true`, callers should avoid calling the lazy value more than once.
- `description`: a description of the value being accessed (usually something like "a.b.c[:blah]") for error messages.

#### LazyValue

Subclasses include:
- `LazyValue`: the type from Chef.  Takes a proc and pops it open on get.
- `LazyClone`: a cacheable (not caching) value that calls `clone` or `dup` on the value before giving it to the caller.  Used for default values.
- `LazyCache`: a wrapper around a CachingLazyValue that caches it and throws away the lazy value when used.
- `LazyAccess`: a `LazyCache` that wraps a lazy value and an operation (method call).  Overridden by `NilSafeLazyAccess`, which can be used in a series to avoid a null pointer exception.

### Proxy

#### Facades

#### Scopes
