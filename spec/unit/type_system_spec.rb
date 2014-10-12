require 'moduler/base/type_system'

describe Moduler::Base::TypeSystem do
  context "With a basic type system" do
    before do
      module Types
        extend Moduler::Base::TypeSystem
        create_local_types
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
        Types.inline do
          attribute :blah
        end
      end
      zzz = Types::ZZZ.new
      zzz.blah = 10
      expect(zzz.blah).to eq 10
    end
  end
end
