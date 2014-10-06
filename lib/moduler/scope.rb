module Moduler
  #
  # +Scope+ is "superclass for instances," allowing one instance to bring
  # another instance into its +self+ scope.  When you use
  # +Moduler::Scope.bring_into_scope(bar, foo)+, calling +bar.x+ will call +foo.x+
  # (assuming +foo+ has an +x+ and +bar+ does not).  This is different from
  # subclassing in that +x+ has access to foo's *data*, while subclassing only
  # has access to foo's methods.
  #
  # The Scope model has a number of nice characteristics:
  # - It lets you bring in multiple scopes
  # - It uses ruby classes with explicit methods, and so avoid the myriad problems
  #   introduced by typical delegators, which use +method_missing+.
  # - It is dynamic: changing Foo will affect instances with a Foo in their scope.
  # - It is simple: a +ScopeProxy+ module is added to each +Scope+ class, and has
  #   proxy methods for each method in the class.  Including a Scope means extending
  #   this module and adding the instance you want to talk to in +@__scopes__+.
  # - It is performant: it uses Ruby for dispatch, avoids metaclasses where
  #   possible with +set_container+ and +@__scopes__+, creates one module per
  #   Scope class, and shares a single function body for all proxy methods.
  #
  # Using Scopes
  # ============
  #
  # 1. Extend +Scope+ in your class.
  #
  #   require 'moduler/scope'
  #
  #   class Friends
  #     extend Moduler::Scope
  #     attr_accessor :fred
  #     attr_accessor :wilma
  #   end
  #
  #   class Countrymen
  #     attr_accessor :shaggy
  #     attr_accessor :thelma
  #   end
  #
  # 2. Link them up.
  #
  #   friends = Friends.new
  #   countrymen = Countrymen.new
  #   Moduler::Scope.bring_into_scope(countrymen, friends)
  #
  #   friends.fred = "Fred"
  #   puts countrymen.fred # Prints Fred
  #   countrymen.wilma = "Wilma"
  #   puts friends.wilma # Prints Wilma
  #
  # Using Container Scope
  # =====================
  #
  # Extending an instance can be powerful and allow runtime mixing of DSLs.
  # However, it incurs a cost: any instance you bring your methods into has a
  # metaclass created for it including the instance.
  #
  # In some cases, you know exactly what type of scope you will bring in--in a
  # containment or subclassing relationship, for example.  You just don't know
  # exactly what *instance* you will link up to until runtime.  This means you
  # should already know what methods you will be calling and can include them
  # in your actual class before runtime.
  #
  # To do this, you call +set_container_class(your_class, container_class)+:
  #
  # 1. Use +set_container_class+ and +set_container+ to link them up:
  #   require 'moduler/scope'
  #
  #   class Friends
  #     extend Moduler::Scope
  #     attr_accessor :fred
  #     attr_accessor :wilma
  #   end
  #
  #   class Countrymen
  #     Moduler::Scope.set_container_class(Countrymen, Friends)
  #     def initialize(friends)
  #       Moduler::Scope.set_container(self, friends)
  #     end
  #     attr_accessor :shaggy
  #     attr_accessor :thelma
  #   end
  #
  # 2. Use them naturally.
  #
  #   friends = Friends.new
  #   countrymen = Countrymen.new(friends)
  #   friends.fred = "Fred"
  #   puts countrymen.fred # Prints Fred
  #   countrymen.wilma = "Wilma"
  #   puts friends.wilma # Prints Wilma
  #
  module Scope
    #
    # Bring another instance into scope in your instance, so that its methods
    # come into your class.
    #
    # ==== Arguments
    # [scope]
    # The scope that will be expanded (will include the other scope).  After the
    # operation, +include_scope+'s public methods will be available to +scope+:
    # +scope.x+ will call +include_scope.x+.
    #
    # [include_scope]
    # The scope that will be included.  +include_scope+ will not be changed in
    # any way; its methods will now be available in +scope+.
    #
    # [override]
    # Set +true+ to make +include_scope+ override any methods in +scope+.  By
    # default, this is +false+, and +scope+ methods will remain visible even if
    # +include_scope+ has methods with the same name.  This chooses between
    # +extend+ (if override is +false+) and +prepend+ (if override is +true+).
    #
    def self.bring_into_scope(scope, include_scope, override=false)
      scope_proxy = include_scope.class.scope_proxy
      if override
        scope_metaclass = class<<scope; self; end
        scope_metaclass.prepend(scope_proxy)
      else
        scope.extend(scope_proxy)
      end
      scope.instance_eval do
        @__scopes__ ||= {}
        @__scopes__[scope_proxy] = include_scope
      end
    end

    #
    # Set the container class for your class.  This is used when you know your
    # class will always have an instance of +container_class+ in scope.  This
    # should be accompanied by using +set_container+ in your class's constructor.
    #
    # ==== Arguments
    # [scope_class]
    # The class whose scope will be expanded (will include the other scope).
    #
    # [container_scope_class]
    # The class whose scope will be included into +scope_class+ instances.
    #
    # [override]
    # Set +true+ to make +container_scope_class+ override any methods in
    # +scope_class+.  By default, this is +false+, and +scope+ methods will
    # remain visible even if +include_scope+ has methods with the same name.
    # This chooses between +include+ (if override is +false+) and +prepend+ (if
    # override is +true+).
    #
    def self.set_container_class(scope_class, container_scope_class, override=false)
      if override
        scope_class.prepend(container_scope_class.scope_proxy)
      else
        scope_class.include(container_scope_class.scope_proxy)
      end
    end

    #
    # Set the actual container.
    #
    # This is generally used in the +initialize+ method after +set_container_class+
    # has been used to link two classes:
    #
    #   class Bar
    #     Moduler::Scope.set_container_class(Bar, Foo)
    #     def initialize(foo)
    #       Moduler::Scope.set_container(self, foo)
    #     end
    #   end
    #
    # ==== Arguments
    # [scope]
    # The scope that will be expanded (methods from container included in scope).
    #
    # [container]
    # The container scope that will be included into +scope+.
    #
    def self.set_container(scope, container)
      scope.instance_eval do
        @__scopes__ ||= {}
        @__scopes__[container.class.scope_proxy] = container
      end
    end

    #
    # This is the method used to actually proxy from one instance to another.
    # We call it "call_other_scope" because it will show up in backtraces,
    # and it would be nice to make clear what is going on.
    #
    def self.call_other_scope
      # Call the same method on our class (in this case, the proxy module calls
      # its class, which is the instance).
      @call_other_scope ||= proc do |*args, &block|
        # Find the proxy module to which the current method is attached
        scope_proxy = self.method(__method__).owner
        # Find the proxy instance
        @__scopes__[scope_proxy].public_send(__method__, *args, &block)
      end
    end

    #
    # Include another scope class or module and your instances will include its
    # instances.
    #
    # ==== Arguments
    # [other]
    # The module being included.  If it is a Scope, your ScopeProxy will include
    # its ScopeProxy so that anyone who uses your Scope will have the included
    # scope as well.
    #
    def include(other)
      super
      if other.is_a?(Scope)
        scope_proxy.include(other.scope_proxy)
      end
    end

    #
    # Get the scope_proxy module for your class, possibly creating it.
    #
    # ==== Returns
    # The ScopeProxy module for your class.  If it does not exist, it creates
    # it under your class and
    #
    def scope_proxy
      @scope_proxy ||= begin
        scope_proxy = const_set(:ScopeProxy, Module.new)

        public_instance_methods(false).each do |method|
          scope_proxy.send(:define_method, method, Scope.call_other_scope)
        end

        ancestors.reverse.each do |ancestor|
          next if ancestor == self
          if ancestor.is_a?(Scope)
            scope_proxy.include(ancestor.scope_proxy)
          end
        end

        scope_proxy
      end
    end

    #
    # When a public method is added, put it in the +ScopeProxy+.
    #
    def method_added(method)
      super
      # We want to define the method only if it is public
      if public_method_defined?(method)
        scope_proxy.send(:define_method, method, Scope.call_other_scope)
      end
    end

    #
    # When a method is undefined, undefine it in the +ScopeProxy+.
    #
    # NOTE: this is tricky.  Because of the way we do inheritance, if you
    # bring both +a+ and +b+ into scope, and +b+ undefs +foo+, +a.foo+ will be
    # hidden too.
    #
    def method_undefined(method)
      super
      # We want to undef the method if it is in ScopeProxy
      if scope_proxy.public_method_defined?(method)
        scope_proxy.send(:undef_method, method)
      end
    end

    #
    # When a method is removed, remove it from the +ScopeProxy+.
    #
    def method_removed(method)
      super
      if scope_proxy.public_method_defined?(method)
        scope_proxy.send(:remove_method, method)
      end
    end

    #
    # When a method is made public, put it into the +ScopeProxy+.
    #
    def public(*methods)
      super
      methods.each do |method|
        scope_proxy.send(:define_method, method, Scope.call_other_scope)
      end
    end

    #
    # When a method is made protected, take it out of the +ScopeProxy+.
    #
    # NOTE: this is a bit tricksy.  If +a+ has +b+ and +c+ in scope, making
    # +c.foo+ private will also hide +b.foo+.  OTOH, it will also hide
    # +c.superclass.foo+, which is what we want.
    #
    def protected(*methods)
      super
      methods.each do |method|
        # We want to undef the method if it is public in the scope proxy, whether
        # it was defined by *our* scope proxy or an included one.
        if scope_proxy.public_method_defined?(method)
          scope_proxy.send(:undef_method, method)
        end
      end
    end

    #
    # When a method is made private, take it out of the +ScopeProxy+.
    #
    # NOTE: this is a bit tricksy.  If +a+ has +b+ and +c+ in scope, making
    # +c.foo+ private will also hide +b.foo+.  OTOH, it will also hide
    # +c.superclass.foo+, which is what we want.
    #
    def private(*methods)
      super
      methods.each do |method|
        # We want to undef the method if it is public in the scope proxy, whether
        # it was defined by *our* scope proxy or an included one.
        if scope_proxy.public_method_defined?(method)
          scope_proxy.send(:undef_method, method)
        end
      end
    end
  end
end
