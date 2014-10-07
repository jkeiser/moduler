require 'support/spec_support'
require 'moduler/type'
require 'moduler/type/struct_type'
require 'moduler/type/coercer'
require 'moduler/type/coercer_out'
require 'moduler/lazy_value'

describe Moduler::Type::StructType do
  LazyValue = Moduler::LazyValue

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
    it "The = setter and getter work" do
      expect(instance.foo = 10).to eq 10
      expect(instance.foo).to eq 10
    end
    it "The method setter works" do
      expect(instance.foo 10).to eq 10
      expect(instance.foo).to eq 10
    end
    it "Lazy value set works" do
      expect(instance.foo LazyValue.new { 100 }).to be_kind_of(LazyValue)
      expect(instance.foo).to eq 100
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

  context "After adding a field with type coercion" do
    let(:field_type) { Moduler::Type.new }
    let(:instance) { type.facade_class.new({}) }
    before do
      field_type = Moduler::Type.new
      field_type.coercers << MultiplyCoercer.new(2)
      field_type.coercers_out << MultiplyCoercerOut.new(3)
      type.field_types[:foo] = field_type
    end

    it "The resulting class has the field getter and setter" do
      expect(type.facade_class.instance_methods(false)).to eq [ :foo, :foo= ]
    end
    it "The setter and getter work" do
      instance.foo = 10
      expect(instance.foo).to eq 60
    end
    it "The method setter works" do
      expect(instance.foo 10).to eq 60
      expect(instance.foo).to eq 60
    end
    it "Lazy value set works" do
      expect(instance.foo LazyValue.new { 100 }).to be_kind_of(LazyValue)
      expect(instance.foo).to eq 600
    end
    # it "Default block setter works" do
    #   block = proc { 100 }
    #   expect(instance.foo(&block)).to eq block
    #   expect(instance.foo.call).to eq 100
    # end
    it "Sending both a value and a block throws an exception" do
      expect { instance.foo(100) { 200 } }.to raise_error ArgumentError
    end
    it "Sending multiple values throws an exception" do
      expect { instance.foo(100, 200) }.to raise_error ArgumentError
    end
  end
  # Reopening a class
  # Inheritance from the class
  # Inheriting *to* the class
  # Methods in existing module
  # Methods in existing class

  class MultiplyCoercer
    extend Moduler::Type::Coercer
    def initialize(n)
      @n = n
    end
    def coerce(value)
      value*@n
    end
  end
  class MultiplyCoercerOut
    extend Moduler::Type::CoercerOut
    def initialize(n)
      @n = n
    end
    def coerce_out(value)
      value*@n
    end
  end
end
