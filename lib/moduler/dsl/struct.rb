require 'moduler/base/module_dsl'

module Moduler
  module Base
    module Struct
      include Moduler::Base::ModuleDSL

      def initialize(*args, &block)
        @attributes = {}
        super
      end

      def add_attribute(name, field_dsl)
        attributes[name] = field_dsl

        # The field_dsl is a module DSL that will feed us the get, set and call
        # methods for our class (including the creation of the Facade), as long as
        # we pass it the expressions to retrieve the underlying value.
        # name=
        expressions = {
          get:     "@#{name}",
          set_var: "value",
          set:     "@#{name} = value",
          set?:    "instance_variable_defined?(@#{name})"
        }

        field_expressions = field_dsl.get_expressions(expressions)

        module_moduler.add_dsl_method("#{name}=", field_expressions[:set], "value") if field_expression[:set]
        module_moduler.add_dsl_method(name,       field_expressions[:call], "*args,&block") if field_expression[:call]
        module_moduler.add_dsl_method(
          "#{field_expressions[:singular_name]}=",
          field_expressions[:singular_set],
          field_expressions[:singular_set_var]
        ) if field_expression[:singular_set]
        module_moduler.add_dsl_method(
          field_expressions[:singular_name],
          field_expressions[:singular_call],
          "*args,&block"
        ) if field_expression[:singular_call]
      end

      def get_expression(expressions)
        module_name = module_moduler.target.name
        expressions[:set] = <<-EOM
          if !#{set_var}.is_a?(#{module_name})
            #{set_var} = #{module_name}.new(#{set_var})
          end
          #{expressions[set]}
        EOM
        super(expressions)
      end

      protected

      attr_reader :attributes
    end
  end
end
