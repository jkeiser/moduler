require 'moduler/specializable'

module Moduler
  module Core
    class Basic
      include Moduler::Specializable

      attr_accessor :target
      attr_accessor :parent

      def self.extended(other)
        if other.is_a?(Module)
          target = other
        end
      end

      def self.inline(&block)
        self.new(target: block.binding.eval('self'), &block)
      end

      def close
        target = nil
        parent = nil
      end

      def create_module(name, options={}, &block)
        if target.const_defined?(name)
          raise "Module #{name} already exists under #{target}!"
        end
        child = Module.new
        target.const_set(name, child)
        self.class.new(options.merge(target: child, parent: self), &block)
      end

      def create_class(name, superclass=nil, options={}, &block)
        if superclass.is_a?(Hash)
          superclass, options = nil, superclass.merge(options)
        end
        if target.const_defined?(name)
          raise "Class #{name} already exists under #{target}!"
        end
        child = Class.new(superclass)
        target.const_set(name, child)
        self.class.new(child, self, options, &block)
      end

      def define_methods(options={}, &block)
        DefineMethods.new(self, options, &block)
      end

      def define_singleton_methods(options={}, &block)
        DefineSingletonMethods.new(self, options, &block)
      end

      class DefineMethods
        include Moduler::Specializable
        def initialize(dsl, base=nil, options={}, &block)
          @dsl = dsl
          super(base, options)
        end

        def method_missing(name, &block)
          @moduler.define_method(name, &block)
        end
      end

      class DefineSingletonMethods < DefineMethods
        def method_missing(name, *args, &block)
          @dsl.define_singleton_method(name, *args, &block)
        end
      end
    end
  end
end
