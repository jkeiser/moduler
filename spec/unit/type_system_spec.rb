require 'moduler/base/type_system'

module TestStuff
end

describe Moduler::Base::TypeSystem do
  context "With a basic type system" do
    before do
      module Types
        def self.type_system
          @@type_system ||= Moduler::Base::TypeSystem.new(Type)
        end
        # Round 1: create the types and link them up in a type system
        class Type
          include Moduler::Base::Mix::Type
          def type_system
            TestTypes.type_system
          end
          def self.attribute(name, *args, &block)
            Types.type_system.emit_attribute self, name, *args, &block
          end
        end
        class TypeType < Type
          include Moduler::Base::Mix::TypeType
        end
        class HashType < Type
          include Moduler::Base::Mix::HashType
        end
        class ArrayType < Type
          include Moduler::Base::Mix::ArrayType
        end
        class SetType < Type
          include Moduler::Base::Mix::SetType
        end
        class StructType < Type
          include Moduler::Base::Mix::StructType
        end
      end
    end

    after do
      Object.send(:remove_const, :Types)
    end

    it "Types are instantiable" do
      Types::Type.new
      Types::TypeType.new
      Types::HashType.new
      Types::ArrayType.new
      Types::SetType.new
      Types::StructType.new
    end

    it "attribute works" do
      class Types::ZZZ
        Types.type_system.emit_attribute self, :blah
      end
      zzz = Types::ZZZ.new
      zzz.blah = 10
      expect(zzz.blah).to eq 10
    end
  end
end
