require 'moduler/specializable'
require 'forwardable'

module Moduler
  module DSL
    #
    # The Basic DSL keeps track of modules and parents, and lets you create
    # DSL inside a module.
    #
    class Basic
      include Moduler::Specializable

      attr_accessor :target
      attr_accessor :parent

      def self.extended(other)
        if other.is_a?(Module)
          target = other
        end
      end

      def self.inline(options={}, &block)
        self.new(options.merge(target: block.binding.eval('self')), &block)
      end

      def module_name(*parts)
        parts.map do |part|
          part.to_s.split('_').select { |p| p.size > 0 }.map { |p| p.capitalize }.join('')
        end.join('').to_sym
      end

      def target_metaclass
        metaclass = class<<target; self; end
      end

      def raw_eval(&block)
        target.module_exec(self, &block)
      end

      def viral_class_methods
        target.instance_eval <<-EOM
          def included(other)
            other.extend(self)
            included_proc = self.method(:included).to_proc
            #{self.class.name}.new(target: other).class_level do
              replace_and_call(:included, included_proc)
            end
          end
        EOM
      end

      def replace_and_call(name, new_proc, &block)
        target.module_eval do
          if method_defined?(:old)
            old_proc = method(name).to_proc
            if block
              define_method(name, block.call(old_proc, new_proc))
            else
              define_method(name) do |*args, &block|
                new_proc.call(*args, &block)
                old_proc.call(*args, &block)
              end
            end
          else
            define_method(name, &new_proc)
          end
        end
      end

      def class_level(options={}, &block)
        self.class.new(options.merge(target: target_metaclass), &block)
      end

      def module_level(options={}, &block)
        self.class.new(options.merge(target: target_metaclass), &block)
      end

      def new_module(name, options={}, &block)
        if target.const_defined?(name)
          raise "Module #{name} already exists under #{target}!"
        end
        child = Module.new
        target.const_set(name, child)
        moduler = self.class.new(options.merge(target: child, parent: self))
        moduler.raw_eval(&block)
        moduler
      end

      def new_class(name, superclass=nil, options={}, &block)
        if superclass.is_a?(Hash)
          superclass, options = nil, superclass.merge(options)
        end
        if target.const_defined?(name)
          raise "Class #{name} already exists under #{target}!"
        end
        child = superclass ? Class.new(superclass) : Class.new
        target.const_set(name, child)
        moduler = self.class.new(options.merge(target: child, parent: self))
        moduler.raw_eval(&block)
        moduler
      end

      def forward(*args)
        raw_eval do
          extend Forwardable
          def_delegators(*args)
        end
      end

      def define_methods(options={}, &block)
        DefineMethods.new(self, options, &block)
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
    end
  end
end
