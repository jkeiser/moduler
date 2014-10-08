require 'support/spec_support'
require 'moduler/lazy_value'
require 'moduler/type/hash_type'

describe Moduler::Type::HashType do
  LazyValue = Moduler::LazyValue

  shared_context "it behaves exactly like a normal hash" do
    it "size works" do
      expect(hash.size).to eq 3
    end
    it "each works" do
      k = :a
      v = 1
      hash.each do |key,val|
        expect(key).to eq k
        expect(val).to eq v
        k = (k.to_s.ord+1).chr.to_sym
        v+=1
      end
    end
    it "each_pair works" do
      k = :a
      v = 1
      hash.each_pair do |key,val|
        expect(key).to eq k
        expect(val).to eq v
        k = (k.to_s.ord+1).chr.to_sym
        v+=1
      end
    end
    it "each_key works" do
      k = :a
      hash.each_key do |key|
        expect(key).to eq k
        k = (k.to_s.ord+1).chr.to_sym
      end
    end
    it "each_value works" do
      v = 1
      hash.each_value do |val|
        expect(val).to eq v
        v+=1
      end
    end
    it "keys works" do
      expect(hash.keys).to eq [:a,:b,:c]
    end
    it "values works" do
      expect(hash.values).to eq [1,2,3]
    end
    it "[] works" do
      expect(hash[:b]).to eq 2
    end
    it "[] for non-key works" do
      expect(hash[:d]).to be_nil
    end
    it "has_key? works" do
      expect(hash.has_key?(:b)).to eq true
      expect(hash.has_key?(:d)).to eq false
    end
    it "[]= works" do
      expect(hash[:b] = 20).to eq 20
      expect(hash).to eq(a:1,b:20,c:3)
    end
    it "[]= for new key works" do
      expect(hash[:d] = 40).to eq 40
      expect(hash).to eq(a:1,b:2,c:3,d:40)
    end
    it "delete works" do
      expect(hash.delete(:b)).to eq 2
      expect(hash).to eq(a:1,c:3)
    end
    it "delete for non-key works" do
      expect(hash.delete(:d)).to be_nil
    end
    it "== works" do
      expect(hash == {a:1,b:2,c:3}).to eq true
      expect(hash == {a:1,b:2,c:3,d:4}).to eq false
    end
  end

  context "With a normal hash" do
    include_context "it behaves exactly like a normal hash" do
      let(:hash) { { a:1,b:2,c:3 } }
    end
  end

  let(:type) { Moduler::Type::HashType.new }
  let(:instance) { type.new_facade(a:1,b:2,c:3) }
  context "With an empty type" do
    include_context "it behaves exactly like a normal hash" do
      let(:hash) { instance }
    end
  end
  context "With a key type" do
  end
  context "With a value type" do
  end
end