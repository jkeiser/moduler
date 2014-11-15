require 'support/spec_support'
require 'moduler/value/lazy'
require 'moduler/type/hash_type'

describe Moduler::Type::HashType do
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

  let(:instance) { type.from_raw(type.to_raw({a:1,b:2,c:3}, nil), nil) }
  context "With an empty type" do
    let(:type) { Moduler::Type::HashType.new }

    include_context "it behaves exactly like a normal hash" do
      let(:hash) { instance }
    end
  end

  class HashStringCoercer < Moduler::Type::BasicType
    def coerce(value, context)
      value.to_s
    end
    def coerce_out(value, context)
      value.to_sym
    end
  end

  context "With a key type" do
    let(:type) { Moduler::Type::HashType.new key_type: HashStringCoercer.new }

    include_context "it behaves exactly like a normal hash" do
      let(:hash) { instance }
      after { hash.raw_read.each_key { |k| expect(k).to be_kind_of(String) } }
      after { hash.each_key { |k| expect(k).to be_kind_of(Symbol) } }
    end

    it "Stores keys internally modified" do
      expect(hash.raw_read).to eq({ 'a' => 1, 'b' => 2, 'c' => 3 })
    end
  end

  context "With a value type" do
    let(:type) { Moduler::Type::HashType.new value_type: MultiplyCoercer.new(in_val: 2, out_val: 0.5) }

    include_context "it behaves exactly like a normal hash" do
      let(:hash) { instance }
      after { hash.raw_read.each_value { |v| expect(v%2).to eq 0 } }
    end

    it "Stores values internally modified" do
      expect(hash.raw_read).to eq({ :a => 2, :b => 4, :c => 6 })
    end
  end

  context "With both a key and a value type" do
    let(:type) { Moduler::Type::HashType.new key_type: HashStringCoercer.new, value_type: MultiplyCoercer.new(in_val: 2, out_val: 0.5) }

    include_context "it behaves exactly like a normal hash" do
      let(:hash) { instance }
      after { hash.raw_read.each_key { |k| expect(k).to be_kind_of(String) } }
      after { hash.each_key { |k| expect(k).to be_kind_of(Symbol) } }
      after { hash.raw_read.each_value { |v| expect(v%2).to eq 0 } }
    end

    it "Stores keys internally modified" do
      expect(hash.raw_read).to eq({ 'a' => 2, 'b' => 4, 'c' => 6 })
    end
  end
end
