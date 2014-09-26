require 'moduler/event'
require 'moduler/errors'

module Moduler
  #
  # Small DSL for creating modules.  Intended to be lightweight, eventable, and
  # possible to switch out for an "on disk" or a "toothless" version.
  #
  class ModuleCreator
    #
    # Define a new module, or reopen an existing module or class.
    #
    # ==== Arguments
    # [parent]
    # The containing class or module.
    # [name]
    # The symbol for the new class (e.g. :MyClass)
    #
    # ==== Returns
    # Returns the created / reopened module.
    #
    # ==== Exceptions
    # TypeError - if the existing constant is not a class.
    #
    # ==== Block
    # The block is run in the context of the new ModuleCreator, and has all DSL
    # methods on it.  When the block terminates, creator.stop is called.
    #
    def self.define(parent, name, &block)
      creator = create(parent, name, Module)
      creator.define(&block)
      creator.target
    end

    #
    # Define a new class, or reopen an existing class.
    #
    # ==== Arguments
    # [parent]
    # The containing class or module (e.g. MyContainingClass::Foo)
    # [name]
    # The symbol for the new class (e.g. :MyClass)
    # [superclass]
    # The superclass of the new class.
    #
    # ==== Returns
    # Returns the created / reopened class.
    #
    # ==== Exceptions
    # TypeError - if the existing constant is not a class.
    #
    # ==== Block
    # The block is run in the context of the new ModuleCreator, and has all DSL
    # methods on it.  When the block terminates, creator.stop is called.
    #
    def self.define_class(parent, name, superclass=nil, &block)
      creator = create(parent, name, Class, &block)
      creator.define(&block)
      creator.target
    end

    #
    # Create a new ModuleCreator DSL against the target module or class.
    #
    def initialize(target)
      @target = target
      @closed = false

      @on_close ||= Event.new(:close, :single_event)
      @on_closed ||= Event.new(:closed, :single_event)
      @on_dsl_added ||= Event.new(:dsl_added, :unregister_on => @on_closed)
    end

    #
    # The target module or class to which methods and DSL are being added.
    #
    attr_reader :target

    #
    # Tells whether this module creator is closed or not.  If it is closed,
    # any attempt to add DSL through this creator will raise an error.
    #
    def closed?
      @closed
    end

    #
    # Close this ModuleCreator, preventing any attempt to add further DSL.
    #
    def close
      if !@closed
        on_close.fire(self)
        @closed = true
        on_closed.fire(self)
      end
    end

    #
    # Run the block in the ModuleCreator context, and call +close+ afterwards.
    #
    # ==== Arguments
    # [name]
    # If specified, will create / reopen the given module nested under this one.
    #
    # ==== Returns
    # Returns the new module if target is specified.
    #
    # ==== Exceptions
    # TypeError - if the existing constant is not a module or class.
    #
    def define(name=nil, &block)
      raise_if_closed
      if name
        creator = self.class.create(target, name, Module, &block)
        on_dsl_added.fire(self, { :type => :nested_module_opened, :target => creator })
        creator.define(&block)
        on_dsl_added.fire(self, { :type => :nested_module_complete, :target => creator })
        creator.target
      else
        instance_eval(&block) if block
        close
      end
    end

    #
    # Define a new subclass nested under this one.
    #
    # ==== Arguments
    # [name]
    # Symbol or Class representing the target class.
    # [superclass]
    # Class to use as the superclass.
    #
    # ==== Returns
    # Returns the new class.
    #
    # ==== Exceptions
    # TypeError - if the existing constant is not a class.
    #
    def define_class(name, superclass=nil, &block)
      raise_if_closed
      creator = self.class.create(target, name, Class, &block)
      on_dsl_added.fire(self, { :type => :nested_module_opened, :target => creator })
      creator.define(&block)
      on_dsl_added.fire(self, { :type => :nested_module_complete, :target => creator })
      creator.target
    end

    #
    # Add some DSL to this class or module.  Accepts either a string or a block.
    # Either will be run in the context of the target class or module.
    #
    def add_dsl(dsl=nil, &block)
      raise_if_closed
      block, dsl = dsl, nil if dsl.is_a?(Proc)
      if dsl
        target.module_eval(dsl)
        on_dsl_added.fire(self, { :type => :dsl, :dsl => dsl })
      end
      if block
        target.module_eval(&block)
        on_dsl_added.fire(self, { :type => :dsl, :dsl => block })
      end
    end

    #
    # Add some DSL to this class or module.  Accepts either a string or a block.
    # Either will be run in the context of the target class or module's metaclass,
    # causing new methods to be added as *self* methods.
    #
    def add_class_dsl(dsl=nil, &block)
      raise_if_closed
      block, dsl = dsl, nil if dsl.is_a?(Proc)
      if dsl
        target.instance_eval(dsl)
        on_dsl_added.fire(self, { :type => :class_dsl, :dsl => dsl })
      end
      if block
        target.instance_eval(&block)
        on_dsl_added.fire(self, { :type => :class_dsl, :dsl => block })
      end
    end

    #
    # Create a new method in the target class or module.  Accepts either a string
    # or a block.
    #
    def add_dsl_method(name, method=nil, &block)
      raise_if_closed
      method = block if block
      if method.is_a?(Proc)
        target.module_eval { define_method(name, &method) }
      else
        target.module_eval "def #{name}\n#{method}\nend"
      end
      on_dsl_added.fire(self, { :type => :dsl_method, :name => name, :proc => method })
    end

    #
    # Create a new class method (def self.x) in the target class or module.
    # Accepts either a string or a block.
    #
    def add_class_dsl_method(name, method=nil, &block)
      raise_if_closed
      metaclass = class<<target; self; end
      method = block if block
      if method.is_a?(Proc)
        target.define_singleton_method(name, &method)
      else
        target.instance_eval "def #{name}\n#{method}\nend"
      end
      on_dsl_added.fire(self, { :type => :class_dsl_method, :name => name, :proc => method })
    end

    #
    # Cause the target module to extend the given module.
    #
    def extend_dsl(extendee)
      raise_if_closed
      target.extend(extendee)
      on_dsl_added.fire(self, { :type => :extended, :module => extendee })
    end

    #
    # Cause the target module to include the given module.
    #
    def include_dsl(includee)
      raise_if_closed
      target.include(includee)
      on_dsl_added.fire(self, { :type => :included, :module => includee })
    end

    #
    # Register an on_close handler, which will fire when the target module is
    # about to be closed.  The event handler is passed the ModuleCreator being
    # closed.
    #
    # ==== Asynchronous Notification
    # When you pass a proc or block, +on_close+ returns immediately and you will
    # be notified when the module is closed.
    #
    #   on_close(proc { ... }), on_close(lambda { ... }) and on_close do ... end
    #
    # ==== Synchronous Listening
    # When you pass a proc as an argument, *and* pass a block, the block is
    # invoked immediately and the listener is unregistered at the end of the
    # block.
    #
    #   on_close(proc { ... }) do ... end
    #
    def on_close(*args, &block)
      if args.size > 0 || block
        @on_close.register(*args, &block)
      else
        @on_close
      end
    end

    #
    # Register an on_closed handler, which will fire after the target module has
    # closed.  The event handler is passed the ModuleCreator that was closed.
    #
    # ==== Asynchronous Notification
    # When you pass a proc or block, +on_closed+ returns immediately and you will
    # be notified when the module is closed.
    #
    #   on_closed(proc { ... }), on_closed(lambda { ... }) and on_closed do ... end
    #
    # ==== Synchronous Listening
    # When you pass a proc as an argument, *and* pass a block, the block is
    # invoked immediately and the listener is unregistered at the end of the
    # block.
    #
    #   on_closed(proc { ... }) do ... end
    #
    def on_closed(*args, &block)
      if args.size > 0 || block
        @on_closed.register(*args, &block)
      else
        @on_closed
      end
    end

    #
    # Register an on_closed handler, which will fire after the target module has
    # closed.  The event handler is passed two arguemnts: the ModuleCreator, and
    # the DSL being added, in the form of a hash that looks like one of these:
    #
    #   { :type => :dsl, :dsl => [block|string] }
    #   { :type => :class_dsl, :class_dsl => [block|string] }
    #   { :type => :dsl_method, :method => :name, :proc => [block|string] }
    #   { :type => :class_dsl_method, :method => :name, :proc => [block|string] }
    #   { :type => :extended, :module => module }
    #   { :type => :included, :module => module }
    #   { :type => :nested_module_opened, :target => <module creator> }
    #   { :type => :nested_module_complete, :target => <module creator> }
    #
    # This call occurs *after* the DSL is actually added to the module.
    #
    # ==== Asynchronous Notification
    # When you pass a proc or block, +on_closed+ returns immediately and you will
    # be notified when the module is closed.
    #
    #   on_closed(proc { ... }), on_closed(lambda { ... }) and on_closed do ... end
    #
    # ==== Synchronous Listening
    # When you pass a proc as an argument, *and* pass a block, the block is
    # invoked immediately and the listener is unregistered at the end of the
    # block.
    #
    #   on_closed(proc { ... }) do ... end
    #
    def on_dsl_added(*args, &block)
      if args.size > 0 || block
        @on_dsl_added.register(*args, &block)
      else
        @on_dsl_added
      end
    end

    protected

    def raise_if_closed
      if closed?
        raise ModuleClosedError.new(self)
      end
    end

    def self.create(parent, name, type)
      if parent.const_defined?(name, false)
        # Reopen the existing module.
        target = parent.const_get(name)
        if !target.is_a?(type)
          raise TypeError, "Attempt to attach #{name} to create a #{type} when #{target} exists and is a #{target.class}."
        end

      else
        # Create a new one if it doesn't exist (or attach the requested module)
        target = type.new
        parent.const_set(name, target)
      end

      # Open us up for DSL, yo!  ModuleCreator.new to the max.
      self.new(target)
    end
  end
end
