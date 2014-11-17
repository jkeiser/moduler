Value
-----

Value is the base class used to guard an underlying Ruby value.  It handles laziness, coercion, and is generally the superclass of "facades" which emulate the interface of the underlying object with the same type guardianship.  You get back a Value if type coercion or laziness are possible for a value.

Values have the following important methods:

| Resource Name | Description |
|---------------|-------------|
|               |             |
|               |             |
|               |             |

### Execution Context

Every Value has an *execution context*, which will be used to evaluate Ruby code (via `instance_eval`).  This becomes important when you set lazy values on an instance or associate code with it.

The `execute` method on a Value executes a Ruby procedure in the Value's context.

```Value.execute(&proc)

### Lazy

### Basic

### Default

This class is used for the special case of a default value.  Until someone *changes* a default value in a struct, we don't store that value.  So when we return an array, a hash, or a struct field as a default, we return one of these; if the user *modifies* the array/hash/struct, we copy-on-write, placing the modified value into the parent.

### Context

All values support *context* in their getters and setters: when you grab or set the value, you pass it a context object with information about where it's being used.  This allows, for example, for default values to have different values depending on where you find them.  This is generally used for Lazy values.

For example:

```ruby
class Database
  extend InlineStruct
  attribute :database_root, Path, default: "~/db"
  attribute :database_config, Path, default: proc { "#{database_root}/db.config" }
end

expect(Database.new.database_config).to == "~/db/db.config"
expect(Database.new(database_root: '/x').database_config).to == "/x/db.config"
expect(Database.new(database_root: '/y').database_config).to == "/y/db.config"
```

In this example, we have one lazy default value, but it is always passed the Database object as its context, so `database_root` in this example always refers to the *instance*'s database_root.

#### How Context Works

All compound values (hash/set/array/struct) have a "context".  For a base struct class, this context is the instance.  For a hash/set/array/struct field, the context is passed in from the accessor that grabbed it (so if you say my_boss.addresses, the address list will have "my_boss" as its context, and my_boss.addresses[0] will have my_boss as its context as well).

This is handled by a pair of things.  First, accessor on compound things like arrays or hashes will pass their context in to the Type method:

```ruby
class ArrayFacade
  def [](index)
    result = element_type.from_raw(raw[index], self.context)
  end
end
```

Next, the Type (which is going to return a Facade anyway) initializes the Facade with the given context.

```ruby
class ArrayType
  def from_raw(raw, context=nil)
    result = ArrayFacade.new(super(raw), context)
  end
end
```

Finally, the compound thing passes the context into the raw call:

```ruby
class ArrayFacade
  def initialize(raw, context)
    @raw = raw
    @context = context
  end
  attr_reader :context
  def raw
    if raw.is_a?(Value)
      raw.get(context)
    end
  end
end
```

This allows the final value (such as a default) to take the context into account:

```ruby
class Lazy
  def get(context)
    if context
      context.instance_eval(&block)
    else
      block.call
    end
  end
end
```


Specialization and Inheritance
------------------------------

Types can be specialized, creating a new type that is an amalgam of the old with some things added and modified.

When you inherit a type, the new type becomes an *overlay* of the old.  You can specify your own overlay rules for type attributes.  As a type is a Struct, standard struct overlay rules apply: new attribute values overlay the old attribute values according to their own rules (arrays append, sets merge, hashes merge and overwrite common values, structs merge and overlay common values).

The `supertype` attribute will be set to the old type.  The `target` attribute will be set to `nil`.

### Classes

The `target` attribute of Struct classes refers to the Ruby class associated with the type.  `target`

### InlineStruct

An InlineStruct is a struct tightly associated with a type.  `target` for an InlineStruct is always known; when an InlineStruct is included into a class or inherited, it gains a new `type` whose supertype is the parent `type`.

### Inline Types

Inline types cause specialization:

```ruby
class Person < InlineStruct
  attribute :name, String
end
class Blah < InlineStruct
  attribute :x, Person do
    attribute :loveable, default: true
  end
end
```

Specialized types always have their own class; these classes are defined inline inside the defining type's class.  Any *new* attributes are declared as methods in the new class.  In the above case, the automatically-created Person subclass looks like:

```ruby
class Person
  def name(value = NOT_PASSED)
    if value != NOT_PASSED
      @name = value
    else
      @name
    end
  end
  def x=(value)
    @name = value
  end
end

class Blah
  def x(*args, &block)
    if args.size > 0 || block
      @x = X.new(*args, &block)
    else
      @x
    end
  end
  def x=(value)
    @x = value
  end

  class X < Person
    def loveable(value = NOT_PASSED)
      if value != NOT_PASSED
        @loveable = value
      else
        @loveable
      end
    end
    def loveable=(value)
      @loveable = value
    end
  end
end
```
