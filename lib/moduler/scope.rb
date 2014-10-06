module Moduler
  #
  # An ExtendableInstance allows another instance to extend it; that instance
  # will be able to access any DSL on the current instance directly inside its
  # +self+.  If any DSL is *added* to the current instance, it will be reflected
  # in the DSL of the extender.
  #
  # How It Works
  # ============
  #
  # If I have a class like this:
  #
  #   class Foo < ExtendableInstance
  #     attr_accessor :foo
  #   end
  #   class Bar
  #     attr_accessor :bar
  #   end
  #   f = Foo.new
  #   b = Bar.new
  #   f.foo = 10
  #   b.bar = 20
  #   b.extend(f)
  #   puts b.foo + b.bar # Prints 30
  #
  # If you are an Extendable:
  # a. If someone extends or superclasses your class, they are an Extendable class too.
  # b. You have a module in your class named ProxyModule.
  # c. When your class is extended or superclassed:
  #    - ProxyModule includes their ProxyModule
  # d. When your instance is created:
  #    - It includes ProxyModule
  # e. When a method is added to your instance:
  #    - It is not included in the target instance :(
  # f. When your instance extends another instance:
  #    - the include thing happens, don't worry about it.
  # g. When another instance extends you:
  #    - You make them include you
  # h. When another instance includes you:
  #    - They can now be extended safely

  #
  # extend Scoped in your class.  A Scope module will be created in your class,
  # which contains proxy methods that proxy back to an instance of your class
  # identified by @__scopes__[scope_module].
  #
  # method_added, method_undefined, method_removed, public, private and protected,
  # and include all cause similar methods in the Scope proxy module.
  #
  #
  #
  # - To include another scope in your scope: +Scoped.extend_scope(you, other)+  (Drawback: this creates a metaclass.  Plus: you can decide what scopes to link at runtime.)
  # - To include another scope for all instances of your class/module: +Scoped.include_scope(your_class, other)
  # - To set your class so that it will always include another scope, but will choose which instance to include at runtime: +Scoped.set_container_class(YourClass, other_class)+ and then +Scoped.set_container_scope(you, other)+ to link your instance to another instance.
  #   This is for situations where the scope relationship between two classes is already
  #   established.
  #
  # -
  # - Subclassing your class will yield a class with the same properties: their
  #   scope_module will include your scope_module.
  # - Including your module will yield a class/module whose scope_module includes your scope_module.
  # - Extending your module will yield an instance that references your scope_module directly
  # - new() does nothing special
  # - +instance.extend_scope(other_instance)+ does +other_instance.extend(scope_module); @__scopes__[scope_module] = instance+
  #
  module Scope
    def self.extend_instance(extender, extendee)
      extender.extend(extendee.class.scope_proxy)
      extender.instance_eval do
        @__scopes__ ||= {}
        @__scopes__[extendee.class.scope_proxy] = extendee
      end
    end

    def self.set_container_class(contained_class, container_class)
      contained_class.include(container_class.scope_proxy)
    end

    def self.set_container(contained, container)
      contained.instance_eval do
        @__scopes__ ||= {}
        @__scopes__[container.class.scope_proxy] = container
      end
    end

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
    def include(other)
      super
      if other.is_a?(Scope)
        scope_proxy.include(other)
      end
    end

    #
    # When we are first asked for the scope_proxy, fill in all public instance
    # methods and ancestors.
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

    def method_added(method)
      super
      puts method.inspect
      if public_instance_methods(false).include?(method)
        scope_proxy.send(:define_method, method, Scope.call_other_scope)
      end
    end

    def method_undefined(method)
      super
      scope_proxy.remove_method(method)
    end

    def method_removed(method)
      super
      scope_proxy.remove_method(method)
    end

    def public(*methods)
      super
      methods.each do |method|
        scope_proxy.send(:define_method, method, Scope.call_other_scope)
      end
    end

    def protected(*methods)
      super
      methods.each do |method|
        scope_proxy.remove_method(method)
      end
    end

    def private(*methods)
      super
      methods.each do |method|
        scope_proxy.remove_method(method)
      end
    end
  end
end
