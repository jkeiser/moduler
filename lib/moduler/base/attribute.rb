module Moduler
  module Base
    module Attribute
      def self.emit_attribute(target, name, type=nil)
        target.send(:define_method, name, attribute_call_proc(name, type))
        target.send(:define_method, :"#{name}=", attribute_set_proc(name, type))
      end

      def self.attribute_call_proc(name, type=nil)
        if type
          proc do |*args, &block|
            result = type.call(StructFieldContext.new(@hash, name), *args, &block)
            result == NO_VALUE ? nil : result
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
    end
  end
end
