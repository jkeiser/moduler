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
    let(:instance) { type.facade_class.new({}) }
    it "The resulting class has the field getter and setter" do
      expect(type.facade_class.instance_methods(false)).to eq [ :foo, :foo= ]
    end
    it "The setter and getter work" do
      expect(instance.foo = 10).to eq 10
      expect(instance.foo).to eq 10
    end
    it "The method setter works" do
      expect(instance.foo 10).to eq 10
      expect(instance.foo).to eq 10
    end
    it "Default block setter works" do
      block = proc { 100 }
      expect(instance.foo(&block)).to eq block
      expect(instance.foo.call).to eq 100
    end
    it "Sending both a value and a block throws an exception" do
      expect { instance.foo(100) { 100 } }.to raise_error ArgumentError
    end
    it "Sending multiple values throws an exception" do
      expect { instance.foo(100, 200) }.to raise_error ArgumentError
    end
  end
end
