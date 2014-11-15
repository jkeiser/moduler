module Moduler
  #
  # +Scope+ is "superclass for instances," allowing one instance to bring
  # another instance into its +self+ scope.  When you use
  # +Moduler::Scope.bring_into_scope(bar, foo)+, calling +bar.x+ will call +foo.x+
  # (assuming +foo+ has an +x+ and +bar+ does not).  This is different from
  # subclassing in that +x+ has access to foo's *data*, while subclassing only
  # has access to foo's methods.
  #
  # Features
  # --------
  # The Scope model has a number of nice characteristics:
  # - It lets you bring in multiple scopes
  # - It uses ruby classes with explicit methods, and so avoid the myriad problems
  #   introduced by typical delegators, which use +method_missing+.
  # - It is dynamic: adding methods to a Scope will be reflected in any instances
  #   that include it.
  # - It is simple: a +ScopeProxy+ module is added to each +Scope+ class, and has
  #   proxy methods for each method in the class.  Including a Scope means extending
  #   this module and adding the instance you want to talk to in +@__scopes__+.
  #
  # Performance
  # -----------
  # - Method calls to the current instance are zero (extra) cost.
  # - Method calls to another scope involve these extra steps:
  #   - 1..n-1 included scopes:
  #     - scope.class.proxy_module.public_method_defined?(__method__)
  #     - If only one scope is included, this overhead is never invoked.
  #     - Since a scope may include other scopes, this can be recursive
  #       up to the depth of the number of scopes.  The O(m,n) == m*n-1,
  #       where m is the depth and n is the number of scopes at each
  #       depth.  Deep scope trees with tons of includes can be
  #       costly.
  #
  # Memory Profile
  # --------------
  # - Each Scope instance has:
  #   - Array of scopes they include (only exists if a scope is included)
  # - Each *included* Scope instance has:
  #   - A proxy module with an include for its superclass and an include for
  #     each new Scope the instance includes
  #   - A metaclass containing the proxy module
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
      # We bring the *instance's* scope_proxy into scope, not just its class;
      # that means if you mix in other scopes into +include_scope+ after this,
      # we'll still pick them up.
      scope_proxy = (class<<include_scope; self; end).scope_proxy

      if override
        # If we're overriding, we want to prepend to the instance's class (which
        # is how you insert the module *in front of* the scope)
        scope_metaclass = class<<scope; self; end
        scope_metaclass.prepend(scope_proxy)
      else
        # Otherwise, we extend the proxy (which does an include to the metaclass).
        scope.extend(scope_proxy)
      end

      # Finally, we add the included scope to scope's @__scopes__ list.
      scope.instance_eval do
        @__scopes__ ||= []
        @__scopes__.unshift(include_scope) # Add to the beginning
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
        # Find out which scope has it.
        size = @__scopes__.size
        @__scopes__[0..-2].each do |scope|
          # We find the first proxy module that defines the method (or if we are
          # at the last proxy, we assume that is the one that defined it).
          if scope.class.proxy_module.public_method_defined?(__method__)
            return scope.public_send(__method__, *args, &block)
          end
        end
        @__scopes__[-1].public_send(__method__, *args, &block)
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
        scope_proxy.send(:include, other.scope_proxy)
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
      if !@scope_proxy
        @scope_proxy = const_set(:ScopeProxy, Module.new)

        public_instance_methods(false).each do |method|
          @scope_proxy.send(:define_method, method, Scope.call_other_scope)
        end

        to_include = []
        handled = Set[@scope_proxy]
        ancestors.each do |ancestor|
          if ancestor.is_a?(Scope)
            next if handled.include?(ancestor.scope_proxy)
            to_include << ancestor.scope_proxy
            handled |= ancestor.scope_proxy.ancestors
          end
        end
        to_include.reverse.each do |m|
          @scope_proxy.send(:include, m)
        end
      end
      @scope_proxy
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
    # NOTE: we cannot intercept public/private/protected, because when we do,
    # Ruby doesn't actually change the visibility of future methods (even if we
    # call super from the public/private/protected method).
    #
    # So when you decrease or increase the visibility of a method, the methods
    # are not added or removed from the proxy class.
    #

    #
    # When a you include a Scope module, you become a Scope yourself.
    #
    def included(other)
      other.extend(Moduler::Scope)
      scope_proxy
    end

    #
    # When a you inherit a Scope module, you become a Scope yourself.
    #
    def inherited(other)
      other.extend(Moduler::Scope)
    end

    #
    # When a you prepend a Scope module, you become a Scope yourself.
    #
    def prepended(other)
      other.extend(Moduler::Scope)
    end
  end
end
