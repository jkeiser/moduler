require 'moduler/specializable'
require 'moduler/facade/accessor'
require 'moduler/facade'

module Moduler
  module DSL
    module Attributes
      def attribute(name, accessor=nil)
        accessor ||= raw_facade
        if !accessor.is_a?(Facade::Accessor)
          accessor = define_instance_variable_access(module_name(:attribute, name), accessor)
        end
        raw_eval do
          define_method(name) do |*args, &block|
            accessor.new(self, name).call(*args, &block)
          end
          define_method("#{name}=") do |value|
            accessor.new(self, name).set(value)
          end
        end
      end

      def attributes(options={}, &block)
        if options.is_a?(Array)
          options = options.inject({}) { |hash,name| hash[name] = nil; hash }
        end
        Attributes.new(self, options, &block)
      end

      class Attributes
        include Moduler::Specializable
        def initialize(moduler, base=nil, options={}, &block)
          @moduler = moduler
          super(base, options)
        end

        def method_missing(name, *args, &block)
          @moduler.attribute(name, *args, &block)
        end
      end

      def include_guards(guards)
        included = []
        extended = []
        guards.each do |guard|
          next if !guard
          if guard.is_a?(Guard)
            target.include guard
            included << guard
          end
          if guard <= Guard::Coercer
            target.extend guard
            extended << guard
          end
        end
        if target.is_a?(Class)
          if included.size == 0
            target.include Guard
          end
          if extended.size == 0
            target.extend Guard::Coercer
          end
        end
      end

      def define_guard_module(name, *guards)
        new_module(name) do |moduler|
          moduler.include_guards(guards)
        end
      end
    end
  end
end
