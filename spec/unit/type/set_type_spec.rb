require 'support/spec_support'
require 'moduler/lazy_value'
require 'moduler/type/set_type'

describe Moduler::Type::SetType do
  LazyValue = Moduler::LazyValue

  shared_context "it behaves exactly like a normal set" do
    it "size works" do
      expect(set.size).to eq 3
    end
    it "each works" do
      i = 1
      set.each { |val| expect(val).to eq i; i+=1 }
    end
    it "to_set works" do
      expect(set.to_set).to eq Set[1,2,3]
    end
    it "to_a works" do
      expect(set.to_a).to eq [1,2,3]
    end
    it "== works" do
      expect(set == Set[1,2,3]).to eq true
      expect(set == [1,2,3]).to eq false
      expect(set == Set[8,9,10]).to eq false
    end
    it "<< works" do
      expect(set << 10).to eq Set[1,2,3,10]
      expect(set).to eq Set[1,2,3,10]
    end
    it "add works" do
      expect(set.add(10)).to eq Set[1,2,3,10]
      expect(set).to eq Set[1,2,3,10]
    end
    it "add? works" do
      expect(set.add?(10)).to eq Set[1,2,3,10]
      expect(set).to eq Set[1,2,3,10]
    end
    it "add? existing returns nil" do
      expect(set.add?(2)).to be_nil
      expect(set).to eq Set[1,2,3]
    end
    it "delete works" do
      expect(set.delete(2)).to eq Set[1,3]
      expect(set).to eq Set[1,3]
    end
    it "delete non-item works" do
      expect(set.delete(10)).to eq Set[1,2,3]
      expect(set).to eq Set[1,2,3]
    end
    it "include? works" do
      expect(set.include?(2)).to eq true
      expect(set.include?(10)).to eq false
    end
    it "member? works" do
      expect(set.member?(2)).to eq true
      expect(set.member?(10)).to eq false
    end
  end

  context "With a normal set" do
    include_context "it behaves exactly like a normal set" do
      let(:set) { Set[1,2,3] }
    end
  end

  let(:type) { Moduler::Type::SetType.new }
  let(:instance) { type.new_facade([1,2,3]) }
  context "With an empty type" do
    include_context "it behaves exactly like a normal set" do
      let(:set) { instance }
    end
  end

  context "With an item type" do
    class SetTypeMultiplyCoercer
      def initialize(amount)
        @amount = amount
      end
      attr_reader :amount
      def coerce(value)
        value * amount
      end
      def coerce_out(value)
        value ? value * amount : value
      end
    end
    before do
      type.item_type = Moduler::Type.new(
        coercer:     SetTypeMultiplyCoercer.new(2),
        coercer_out: SetTypeMultiplyCoercer.new(5)
      )
    end
    let(:set) { instance }

    it "size works" do
      expect(set.size).to eq 3
    end
    it "each works" do
      i = 1
      set.each { |val| expect(val).to eq i*10; i+=1 }
    end
    it "to_set works" do
      expect(set.to_set).to eq Set[10,20,30]
    end
    it "to_a works" do
      expect(set.to_a).to eq [10,20,30]
    end
    it "== works" do
      expect(set == Set[10,20,30]).to eq true
      expect(set == [10,20,30]).to eq false
      expect(set == Set[8,9,10]).to eq false
    end
    it "<< works" do
      expect(set << 10).to eq Set[10,20,30,100]
      expect(set).to eq Set[10,20,30,100]
    end
    it "add works" do
      expect(set.add(10)).to eq Set[10,20,30,100]
      expect(set).to eq Set[10,20,30,100]
    end
    it "add? works" do
      expect(set.add?(10)).to eq Set[10,20,30,100]
      expect(set).to eq Set[10,20,30,100]
    end
    it "add? existing returns nil" do
      expect(set.add?(2)).to be_nil
      expect(set).to eq Set[10,20,30]
    end
    it "delete works" do
      expect(set.delete(2)).to eq Set[10,30]
      expect(set).to eq Set[10,30]
    end
    it "delete non-item works" do
      expect(set.delete(10)).to eq Set[10,20,30]
      expect(set).to eq Set[10,20,30]
    end
    it "include? works" do
      expect(set.include?(2)).to eq true
      expect(set.include?(10)).to eq false
    end
    it "member? works" do
      expect(set.member?(2)).to eq true
      expect(set.member?(10)).to eq false
    end
  end
end
