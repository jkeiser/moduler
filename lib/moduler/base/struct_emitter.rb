require 'moduler/facade/struct'
require 'moduler/facade/hash_struct_facade'
require 'moduler/value/typed'
require 'moduler/base/type'
require 'moduler/base/hash_type'
require 'moduler/value/default'

module Moduler
  module Base
    class StructType < Type
      def emit(parent=nil, name=nil)
        if !target && parent && name
          self.target = { parent: parent, name: name }
          if supertype && supertype.target
            # TODO fix this messiness ASAP and apply to *everything*
            if !supertype.target.name.start_with?("Moduler")
              if supertype.target.is_a?(Class)
                self.target[:superclass] = supertype.target
              else
                self.target[:include] = [ supertype.target ]
              end
            end
          end
        end
        emit_target_class_type
        attributes.map do |name,field_type|
          emit_field(name)
        end
      end

      def emit_field(name)
        field_type = @attributes[name]
        if field_type
          type_ref = "method(__method__).owner.type.attributes[#{name.inspect}]"
          emit_get_set_field(name, type_ref)

          if field_type.is_a?(Moduler::Base::HashType) && field_type.singular
            emit_singular_hash_field(field_type.singular, name, type_ref)
          end

          field_type.emit(target, name)
        else
          emit_typeless_get_set_field(name)
        end
      end

      protected

      def emit_target_class_type
        # Create the target class if asked
        if target.is_a?(Hash)
          includees = target[:include]
          @target = eval <<-EOM, binding, __FILE__, __LINE__+1
            class target[:parent]::#{to_camel_case(target[:name])}#{target[:superclass] ? " < target[:superclass]" : ""}
              self
            end
          EOM
          if includees
            includees.each do |includee|
              @target.send(:include, includee)
            end
          end
        end

        # Set the type on the class
        if target.respond_to?(:has_type?)
          has_type = target.has_type?
        else
          has_type = target.respond_to?(:type) && target.type && target.type.target == target
        end
        if has_type
          if target.type != self
            raise "Tried to emit #{self} to #{target}, but #{target.type} is already being emitted there!"
          end
        else
          local_type = self
          target.instance_eval <<-EOM, __FILE__, __LINE__+1
            def type
              @type
            end
            @type = local_type
          EOM
        end

        if store_in_hash
          target.class_eval "include Moduler::Facade::HashStructFacade"
        else
          target.class_eval "include Moduler::Facade::Struct"
        end
      end

      # foo_bar/baz_bonk -> FooBar::BazBonk
      def to_camel_case(snake_case)
        snake_case.to_s.split('/').map do |str|
          str.split('_').map { |s| s.capitalize }.join('')
        end.join('::')
      end

      # FooBar::BazBonk -> foo_bar/baz_bonk
      if RUBY_VERSION.to_f >= 2
        UPPERCASE_SPLIT = Regexp.new('(?=\p{Lu})')
      else
        UPPERCASE_SPLIT = Regexp.new('(?=[A-Z])')
      end
      def to_snake_case(camel_case)
        camel_case.to_s.split('::').map do |str|
            str.split(UPPERCASE_SPLIT).map { |s| s.downcase! }.join('_')
        end.join('/')
      end

      def is_set_expr(name)
        store_in_hash ? "raw_read.has_key?(#{name.inspect})" : "defined?(@#{name})"
      end

      def context_expr
        # Right now, top level structs are store_in_hash, all else are hashes
        store_in_hash ? "context" : "self"
      end

      def attribute_read(name)
        store_in_hash ? "raw_read[#{name.inspect}]" : "@#{name}"
      end

      def attribute_write(name)
        store_in_hash ? "raw[#{name.inspect}]" : "@#{name}"
      end

      def emit_get_set_field(name, type_ref)
        target.module_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(*args, &block)
            if args.size == 0 && !block
              if #{is_set_expr(name)}
                raw_value = #{attribute_read(name)}
              else
                # We don't set defaults into the struct right away; only if the
                # user tries to write to them.  Frozen defaults (like an int)
                # we don't store at all.
                raw_default = #{type_ref}.raw_default

                if raw_default.frozen? || raw_default.nil?
                  raw_value = raw_default
                else
                  raw_value = Value::Default.new(raw_default) do
                    if #{is_set_expr(name)}
                      raise "#{name} was defined by someone else: race!"
                    else
                      #{attribute_write(name)} = raw_default
                    end
                  end
                end
              end
              #{type_ref}.from_raw(raw_value, #{context_expr})
            else
              raw_value = #{type_ref}.construct_raw(#{context_expr}, *args, &block)
              #{attribute_write(name)} = raw_value
              nil
            end
          end
          def #{name}=(value)
            value = #{type_ref}.to_raw(value, #{context_expr})
            #{attribute_write(name)} = value
            # NOTE: Ruby doesn't let you return a value here anyway--it will always
            # return the passed-in value to the user.
          end
        EOM
      end

      def emit_typeless_get_set_field(name)
        target.module_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(value=NOT_PASSED, &block)
            if value == NOT_PASSED
              if block
                #{attribute_write(name)} = block
              else
                puts "Getting a" if #{name.inspect} == :a
                #{attribute_read(name)}
              end
            else
              #{attribute_write(name)} = value
            end
          end
          def #{name}=(value)
            #{attribute_write(name)} = value
          end
        EOM
      end

      def emit_singular_hash_field(method_name, attribute_name, type_ref)
        target.module_eval <<-EOM, __FILE__, __LINE__+1
          def #{method_name}(*args, &block)
            if args.size == 0
              raise ArgumentError, "#{method_name} requires at least one argument: #{method_name} <key>, <value> or #{method_name} <key> => <value>, <key> => <value> ..."
            end

            # The plural value
            if args[0].is_a?(Hash) && args.size == 1 && !block
              # If we get a hash, we merge in the values
              #{attribute_write(attribute_name)}.merge!(args[0])
            else
              key = args.shift
              value_type = #{type_ref}.value_type
              if value_type
                value = value_type.construct_raw(#{context_expr}, *args, &block)
                #{attribute_write(attribute_name)}[key] = value
                value_type.from_raw(value, #{context_expr})
              elsif args.size == 1 && !block
                #{attribute_write(attribute_name)}[key] = args[0]
              elsif args.size == 0 && block
                #{attribute_write(attribute_name)}[key] = block
              else
                raise ArgumentError, "#{method_name} takes exactly two arguments: #{method_name} <key>, <value> or #{method_name} <key> => <value>, <key> => <value> ..."
              end
            end
          end
        EOM
      end
    end
  end
end
