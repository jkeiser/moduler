require 'moduler/base/type'

module Moduler
  module Base
    class TypeType < Type
      def start_construction_from?(type)
        coerce?(type)
      end

      def coerce?(type)
        case type
        when Hash
          Type.new(type)
        when Proc
          Type.new(&type)
        when Type
          type
        end
      end

      def coerce(type)
        result = coerce?(type)
        if !result
          raise ValidationFailed, "#{type} cannot be converted to #{self.class}"
        end
      end

      # This breaks a loop
      module Moduler::Base::SpecializableType; end
      include SpecializableType
      require 'moduler/base/specializable_type'
    end
  end
end
