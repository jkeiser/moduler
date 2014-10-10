require 'support/spec_support'
require 'moduler/type'
require 'moduler/type/struct_type'
require 'moduler/validation/coercer'
require 'moduler/validation/coercer_out'
require 'moduler/lazy_value'

describe Moduler::Type::StructType do
  let(:type) { Moduler::Type::StructType.new }
  context "With no modifications" do
    it "The resulting class has no instance methods" do
      expect(type.facade_class.instance_methods(false)).to eq [ :to_s, :inspect ]
    end
  end
  context "After adding a field" do
    before { type.attributes[:foo] = Moduler::Type.new }
    let(:instance) { type.restore_facade({}) }
    it "The resulting class has the field getter and setter" do
      expect(type.facade_class.instance_methods(false)).to eq [ :to_s, :inspect, :foo, :foo= ]
    end
    it "The default getter returns nil" do
      expect(instance.foo).to eq nil
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
      expect(instance.foo Moduler::LazyValue.new { 100 }).to be_kind_of(Moduler::LazyValue)
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
    let(:attribute) { Moduler::Type.new }
    let(:instance) { type.restore_facade({}) }
    let(:on_set) { [] }
    before do
      attribute = Moduler::Type.new
      attribute.coercer = MultiplyCoercer.new(2)
      attribute.coercer_out = MultiplyCoercerOut.new(3)
      attribute.register(:on_set) do |v|
        expect(v.type).to eq attribute
        on_set << v.value
      end
      type.attributes[:foo] = attribute
    end

    it "The resulting class has the field getter and setter" do
      expect(type.facade_class.instance_methods(false)).to eq [ :to_s, :inspect, :foo, :foo= ]
    end
    it "The default getter returns nil" do
      expect(instance.foo).to eq nil
      expect(on_set).to eq []
    end
    it "The setter and getter work" do
      instance.foo = 10
      expect(instance.foo).to eq 60
      expect(on_set).to eq [ 60 ]
    end
    it "The method setter works" do
      expect(instance.foo 10).to eq 60
      expect(instance.foo).to eq 60
      expect(on_set).to eq [ 60 ]
    end
    it "Lazy value set works" do
      expect(instance.foo Moduler::LazyValue.new { 100 }).to be_kind_of(Moduler::LazyValue)
      expect(instance.foo).to eq 600
      expect(on_set).to eq [ 600 ]
    end
    # it "Default block setter works" do
    #   block = proc { 100 }
    #   expect(instance.foo(&block)).to eq block
    #   expect(instance.foo.call).to eq 100
    # end
    it "Sending both a value and a block throws an exception" do
      expect { instance.foo(100) { 200 } }.to raise_error ArgumentError
      expect(on_set).to eq []
    end
    it "Sending multiple values throws an exception" do
      expect { instance.foo(100, 200) }.to raise_error ArgumentError
      expect(on_set).to eq []
    end
  end

  context "After adding a struct field" do
    let(:on_set) { [] }
    before do
      attribute = Moduler::Type::StructType.new
      attribute.attributes[:bar] = Moduler::Type.new
      type.attributes[:foo] = attribute

      attribute.register(:on_set) do |v|
        expect(v.type).to eq attribute
        on_set << v.value
      end
    end
    let(:foo_struct) { type.facade_class }
    let(:instance) { type.restore_facade({}) }
    let(:struct) { type.attributes[:foo].facade_class }

    it "The resulting class has the field getter and setter" do
      expect(type.facade_class.instance_methods(false)).to eq [ :to_s, :inspect, :foo, :foo= ]
      expect(on_set).to eq []
    end
    it "The default getter returns nil" do
      expect(instance.foo).to eq nil
      expect(on_set).to eq []
    end
    it "Set to a foo_struct value works" do
      value = struct.new(bar: 10)
      instance.foo = value
      expect(instance.foo.object_id).to eq value.object_id
      expect(on_set).to eq [ struct.new(bar: 10) ]
    end
    it "The setter and getter work" do
      instance.foo = { bar: 10 }
      struct.new(bar: 10)
      expect(instance.foo).to eq struct.new(bar: 10)
      expect(on_set).to eq [ struct.new(bar: 10) ]
    end
    it "The method setter works" do
      expect(instance.foo bar: 10).to eq struct.new(bar: 10)
      expect(instance.foo).to eq struct.new(bar: 10)
      expect(on_set).to eq [ struct.new(bar: 10) ]
    end
    it "Lazy value set works" do
      expect(instance.foo Moduler::LazyValue.new { { bar: 10 } }).to be_kind_of(Moduler::LazyValue)
      expect(instance.foo).to eq struct.new(bar: 10)
      expect(on_set).to eq [ struct.new(bar: 10) ]
    end
    it "Default block setter sets struct properties" do
      expect(instance.foo { bar 10 }).to eq struct.new(bar: 10)
      expect(instance.foo).to eq struct.new(bar: 10)
      expect(on_set).to eq [ struct.new(bar: 10) ]
    end
    it "Setter with both a value and a block works" do
      expect(instance.foo(bar: 10) { bar bar * 2 }).to eq struct.new(bar: 20)
      expect(on_set).to eq [ struct.new(bar: 20) ]
    end
    it "Sending multiple values throws an exception" do
      expect { instance.foo({bar: 10}, {bar: 20}) }.to raise_error ArgumentError
      expect(on_set).to eq []
    end
  end

  # Reopening a class
  # Inheritance from the class
  # Inheriting *to* the class
  # Methods in existing module
  # Methods in existing class

  class MultiplyCoercer
    extend Moduler::Validation::Coercer
    def initialize(n)
      @n = n
    end
    def coerce(value)
      value*@n
    end
  end
  class MultiplyCoercerOut
    extend Moduler::Validation::CoercerOut
    def initialize(n)
      @n = n
    end
    def coerce_out(value)
      value*@n
    end
  end
end
