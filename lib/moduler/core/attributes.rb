module Moduler
  module Core
    module Attributes
      def attribute(name, facade=nil)
        if facade
          instance_var = moduler.instance_variable_access(facade)
        end

        target.define_method(name) { instance_var.new(self).call)
        target.define_method("#{name=}", expr.set)
      end

      def class_attribute(name, expr=nil)
        expr ||= value_expressions(
          input: "@#{name}",
          output: "@#{name}",
          set: ['value', "@#{name} = {{value}}"]
        ])
        class_method(name, expr.attribute_call)
        class_method("#{name=}", expr.set)
      end

      def attributes(options={}, &block)
        if options.is_a?(Array)
          options = options.inject({}) { |hash,name| hash[name] = nil; hash }
        end
        Attributes.new(self, options, &block)
      end

      def class_attributes(options={}, &block)
        if options.is_a?(Array)
          options = options.inject({}) { |hash,name| hash[name] = nil; hash }
        end
        ClassAttributes.new(self, options, &block)
      end

      class Attributes
        include Moduler::Base::Specializable
        def initialize(moduler, base=nil, options={}, &block)
          @moduler = moduler
          super(base, options)
        end

        def method_missing(name, *args, &block)
          @moduler.attribute(name, *args, &block)
        end
      end

      class ClassAttributes < Methods
        def method_missing(name, *args, &block)
          @moduler.class_attribute(name, *args, &block)
        end
      end
    end
  end
end
