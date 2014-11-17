require 'support/spec_support'
require 'moduler/type/struct_type'
require 'moduler/value/lazy'

describe Moduler::Type::StructType do
  let(:type) { Moduler::Type::StructType.new(target: Class.new) }
  context "With no modifications" do
    it "The resulting class has no instance methods" do
      expect(type.target.instance_methods(false)).to eq [ ]
    end
  end
  context "After adding a field" do
    before do
      type.attribute :foo
      type.emit
    end
    let(:instance) { type.target.new }
    it "The resulting class has the field getter and setter" do
      expect(type.target.instance_methods(false)).to eq [ :foo, :foo= ]
    end
    it "The default getter returns nil" do
      expect(instance.foo).to eq nil
    end
    it "The = setter and getter work" do
      expect(instance.foo = 10).to eq 10
      expect(instance.foo).to eq 10
    end
    it "The method setter works" do
      instance.foo 10
      expect(instance.foo).to eq 10
    end
    it "Lazy value set works" do
      instance.foo Moduler::Value::Lazy.new { 100 }
      expect(instance.foo).to eq 100
    end
    it "Default block setter works" do
      block = proc { 100 }
      instance.foo(&block)
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
    let(:instance) { type.target.new }
    before do
      type.attribute :foo, MultiplyCoercer.new(in_val: 2, out_val: 3)
      type.emit
    end

    it "The resulting class has the field getter and setter" do
      expect(type.target.instance_methods(false)).to eq [ :foo, :foo= ]
    end
    it "The default getter returns nil" do
      expect(instance.foo).to eq nil
    end
    it "The setter and getter work" do
      instance.foo = 10
      expect(instance.foo).to eq 60
    end
    it "The method setter works" do
      instance.foo 10
      expect(instance.foo).to eq 60
    end
    it "Lazy value set works" do
      instance.foo Moduler::Value::Lazy.new { 100 }
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

  context "After adding a struct field" do
    let(:type) do
      type = Moduler::Type::StructType.new do
        target Class.new { define_singleton_method(:to_s) { puts "outer struct" }}
        attribute :foo, Struct do
          attribute :bar
        end
      end
      type.emit
      type.attributes[:foo].emit
      type
    end
    let(:foo_struct) { type.target }
    let(:instance) { type.target.new }
    let(:struct) { type.attributes[:foo].target }

    it "The resulting class has the field getter and setter" do
      expect(foo_struct.instance_methods(false)).to eq [ :foo, :foo= ]
    end
    it "The default getter returns {}" do
      expect(instance.foo).to eq({})
    end
    it "Set to a foo_struct value works" do
      value = struct.new(bar: 10)
      instance.foo = value
      expect(instance.foo).to eq value
    end
    it "The setter and getter work" do
      instance.foo = { bar: 10 }
      struct.new(bar: 10)
      expect(instance.foo).to eq struct.new(bar: 10)
    end
    it "The method setter works" do
      instance.foo bar: 10
      expect(instance.foo).to eq struct.new(bar: 10)
    end
    it "Lazy value set works" do
      instance.foo Moduler::Value::Lazy.new { { bar: 10 } }
      expect(instance.foo).to eq struct.new(bar: 10)
    end
    it "Default block setter sets struct properties" do
      instance.foo { bar 10 }
      expect(instance.foo).to eq struct.new(bar: 10)
    end
    it "Setter with both a value and a block works" do
      instance.foo(bar: 10) { bar bar * 2 }
      expect(instance.foo).to eq struct.new(bar: 20)
    end
    it "Sending multiple values throws an exception" do
      expect { instance.foo({bar: 10}, {bar: 20}, {wah: 30}) }.to raise_error ArgumentError
    end
  end

  # Reopening a class
  # Inheritance from the class
  # Inheriting *to* the class
  # Methods in existing module
  # Methods in existing class

end
