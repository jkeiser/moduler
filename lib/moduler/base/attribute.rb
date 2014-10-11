module Moduler
  module Base
    module Attribute
      def self.emit_attribute(target, name, type=nil)
        target.send(:define_method, name, attribute_call_proc(name, type))
        target.send(:define_method, :"#{name}=", attribute_set_proc(name, type))
      end

      def self.attribute_call_proc(name, type=nil)
        if type
          # If the type has a raw get (no coercion on output) then we skip
          # the "call."
          if type.raw_get?
            proc do |*args, &block|
              if args.size == 0 && !block
                # Handles lazy values and defaults for you
                result = @hash[name]
                if !result
                  if !@hash.has_key?(name)
                    result = type.raw_default { |v| @hash[name] = v }
                    result = nil if result == NO_VALUE
                  end
                elsif result.is_a?(LazyValue)
                  type.raw_value(@hash[name]) { |v| @hash[name] = v }
                end
                result
              else
                type.call(StructFieldContext.new(@hash, name), *args, &block)
              end
            end
          else
            proc do |*args, &block|
              type.call(StructFieldContext.new(@hash, name), *args, &block)
            end
          end
        else
          proc do |value=NOT_PASSED, &block|
            if value == NOT_PASSED
              if block
                @hash[name] = block
              else
                @hash[name]
              end
            else
              @hash[name] = value
            end
          end
        end
      end

      def self.attribute_set_proc(name, type=nil)
        if type
          proc do |value|
            value = type.coerce(value)
            @hash[name] = value
            type.fire_on_set_raw(value)
            # NOTE: Ruby doesn't let you return a value here anyway--it will always
            # return the passed-in value to the user.
          end
        else
          proc { |value| @hash[name] = value }
        end
      end

      def self.singular_hash_proc(name, type=nil)
        if type
          proc do |*args, &block|
            if args.size == 0
              raise ArgumentError, "#{singular} requires at least one argument: #{singular} <key>, <value> or #{singular} <key> => <value>, <key> => <value> ..."
            end

            # The plural value
            if args[0].is_a?(Hash) && args.size == 1 && !block
              # If we get a hash, we merge in the values
              if args[0].size > 0
                @hash[name] ||= {}
                attribute_value = @hash[name]
                args[0].each do |key,value|
                  key = type.coerce_key(key)
                  value = type.coerce_value(value)
                  attribute_value[key] = value
                  type.value_type.fire_on_set_raw(value) if type.value_type
                end
              end
            else
              # If we get :key, ... do ... end, we do the standard get/set with it.
              key = type.coerce_key(args.shift)
              context = HashValueContext.new(@hash, name, key)
              if type.value_type
                type.value_type.call(context, *args, &block)
              else
                # Call the empty type if there is no value type
                type_system.base_type.call(context, *args, &block)
              end
            end
          end
        else
          proc do |*args, &block|
            if args.size == 0
              raise ArgumentError, "#{singular} requires at least one argument: #{singular} <key>, <value> or #{singular} <key> => <value>, <key> => <value> ..."
            end

            # The plural value
            if args[0].is_a?(Hash) && args.size == 1 && !block
              # If we get a hash, we merge in the values
              @hash[name] ||= {}
              @hash[name].merge!(args[0])
            else
              # If we get :key, ... do ... end, we do the standard get/set with it.
              key = args[0]
              if args.size == 1
                if block
                  @hash[name] ||= {}
                  @hash[name][key] = block
                else
                  @hash.has_key?(name) ? @hash[name][key] : nil
                end
              elsif args.size == 2
                if block
                  raise ArgumentError, "Adding #{key} to #{name} failed: sending arguments and taking a block not supported (arguments: #{args})"
                end
                @hash[name] ||= {}
                @hash[name][key] = args[1]
              else
                raise ArgumentError, "Adding #{key} to #{name} failed: too many arguments (#{args.size} for 2).  Passed #{args}"
              end
            end
          end
        end
      end

      class StructFieldContext
        def initialize(hash, name)
          @hash = hash
          @name = name
        end
        def get
          if @hash.has_key?(@name)
            @hash[@name]
          else
            NO_VALUE
          end
        end

        def set(value)
          @hash[@name] = value
        end
      end

      class HashValueContext
        def initialize(attributes, name, key)
          @attributes = attributes
          @name = name
          @key  = key
        end

        def get
          if @attributes[@name] && @attributes[@name].has_key?(@key)
            @attributes[@name][@key]
          else
            NO_VALUE
          end
        end

        def set(value)
          @attributes[@name] ||= {}
          @attributes[@name][@key] = value
        end
      end
    end
  end
end
