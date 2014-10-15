require 'moduler/base/value_context'
require 'moduler/facade/struct'
require 'moduler/base/hash_type'

module Moduler
  class Emitter
    def initialize(type, target)
      @target = target
      @type = type
    end

    attr_accessor :target
    attr_accessor :type

    def emit_target_class_type
      # Create the target class if asked
      if target.is_a?(Hash)
        @target = eval <<-EOM, __FILE__, __LINE__+1
          class target[:parent]::#{to_camel_case(target[:name])}#{target[:superclass] ? " < target[:superclass]" : ""}
            self
          end
        EOM
      end

      if type && type.target && type.target != target
        raise "Tried to emit #{type} to #{target}, but it's already being emitted to #{type.target}!"
      end

      # Set the type on the class
      if target.respond_to?(:type) && target.type
        if target.type != type
          raise "Tried to emit #{type} to #{target}, but #{target.type} is already being emitted there!"
        end
      else
        local_type = type
        target.instance_eval <<-EOM, __FILE__, __LINE__+1
          def type
            @type
          end
          @type = local_type
        EOM
      end
    end

    def emit
      emit_target_class_type
    end

    def type_reference(type)
      "#{target.name}.type"
    end

    # foo_bar/baz_bonk -> FooBar::BazBonk
    def to_camel_case(snake_case)
      snake_case.split('/').map do |str|
        str.split('_').map { |s| s.capitalize }.join('')
      end.join('::')
    end

    # FooBar::BazBonk -> foo_bar/baz_bonk
    def to_snake_case(camel_case)
      camel_case.split('::').map do |str|
        str.split(/(?=\p{Lu})/).map { |s| s.downcase! }.join('_')
      end.join('/')
    end

    def self.emit(type, target)
      case type
      when Moduler::Base::StructType, nil
        StructEmitter.new(type, target).emit
      else
        raise "Unexpected type #{type}"
      end
    end

    class StructEmitter < Emitter
      def emit
        super

        type.attributes.map do |name,field_type|
          emit_field(name, field_type)
        end
      end

      def emit_target_class_type
        super
        target.class_eval "include Moduler::Facade::Struct"
      end

      def emit_field(name, field_type)
        if field_type
          type_ref = "#{type_reference(type)}.attributes[#{name.inspect}]"
          # If the type has a raw get (no coercion on output) then we skip
          # the "call."
          if field_type.raw_get?
            emit_raw_get_field(name, type_ref)
          else
            emit_get_field(name, type_ref)
          end

          emit_set_field(name, type_ref)

          if field_type.is_a?(Moduler::Base::HashType) && field_type.singular
            emit_singular_hash_field(field_type.singular, name, field_type)
          end
        else
          emit_typeless_get_set_field(name)
        end
      end

      def emit_raw_get_field(name, type_ref)
        target.module_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(*args, &block)
            if args.size == 0 && !block
              # Handles lazy values and defaults for you
              result = @#{name}
              if !result
                if !defined?(@#{name})
                  result = #{type_ref}.raw_default { |v| @#{name} = v }
                  result = nil if result == NO_VALUE
                end
              elsif result.is_a?(Moduler::LazyValue)
                result = #{type_ref}.raw_value(@#{name}) { |v| @#{name} = v }
              end
              result
            else
              value = defined?(@#{name}) ? @#{name} : NO_VALUE
              context = Moduler::Base::ValueContext.new(value) { |v| @#{name} = v }
              #{type_ref}.call(context, *args, &block)
            end
          end
        EOM
      end

      def emit_get_field(name, type_ref)
        target.module_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(*args, &block)
            value = defined?(@#{name}) ? @#{name} : NO_VALUE
            context = Moduler::Base::ValueContext.new(value) { |v| @#{name} = v }
            #{type_ref}.call(context, *args, &block)
          end
        EOM
      end

      def emit_typeless_get_set_field(name)
        target.module_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(value=NOT_PASSED, &block)
            if value == NOT_PASSED
              if block
                @#{name} = block
              else
                @#{name}
              end
            else
              @#{name} = value
            end
          end
          def #{name}=(value)
            @#{name} = value
          end
        EOM
      end

      def emit_set_field(name, type_ref)
        target.module_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}=(value)
            value = #{type_ref}.coerce(value)
            @#{name} = value
            # NOTE: Ruby doesn't let you return a value here anyway--it will always
            # return the passed-in value to the user.
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
              if args[0].size > 0
                @#{attribute_name} ||= {}
                args[0].each do |key,value|
                  key = #{type_ref}.coerce_key(key)
                  value = #{type_ref}.coerce_value(value)
                  @#{attribute_name}[key] = value
                end
              end
            else
              # If we get :key, ... do ... end, we do the standard get/set with it.
              key = #{type_ref}.coerce_key(args.shift)
              if defined?(@#{attribute_name})
                if @#{attribute_name}.has_key?(key)
                  value = @#{attribute_name}[key]
                else
                  value = NO_VALUE
                end
              else
                value = NO_VALUE
              end
              context = Moduler::Base::ValueContext.new(value) do |v|
                @#{attribute_name} ||= {}
                @#{attribute_name}[key] = v
              end
              #{type_ref}.value_type.call(context, *args, &block)
            end
          end
        EOM
      end
    end
  end
end
