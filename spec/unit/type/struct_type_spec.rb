require 'moduler/type/struct_type'

describe Moduler::Type::StructType do
  let(:type) { Moduler::Type::StructType.new }
  context "With no modifications" do
    it "The resulting class has no instance methods" do
      expect(type.facade_class.instance_methods(false).size).to eq 0
    end
  end
  context "After adding a field" do
    before { type.field_types[:foo] = Moduler::Type.new }
    it "The resulting class has the field getter and setter" do
      expect(type.facade_class.instance_methods(false)).to eq [ :foo, :foo= ]
    end
    it "The setter and getter work" do
      foo = type.facade_class.new({})
      expect(foo.foo = 10).to eq 10
      expect(foo.foo).to eq 10
    end
  end
end
