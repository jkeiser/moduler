require 'support/spec_support'
require 'moduler/type'
require 'moduler/lazy/value'

describe Moduler::Type do
  let(:type) do
    Moduler::Type.new
  end

  describe "to_raw" do
    #after { expect(on_set).to eq [] }

    it "By default, to_raw returns the input value" do
      expect(type.to_raw(100)).to eq 100
      expect(type.to_raw(nil)).to be_nil
    end

    it "When a coercer is specified, it is called" do
      type = MultiplyCoercer.new in_val: 2
      expect(type.to_raw(100)).to eq 200
    end

    it "When given a lazy value, coercers are not run and the value is returned" do
      type = MultiplyCoercer.new in_val: 2
      lazy = Moduler::Lazy::Value.new { 100 }
      expect(type.to_raw(lazy)).to eq lazy
    end

    it "When given a non-caching lazy value, coercers are not run and the value is returned" do
      type = MultiplyCoercer.new in_val: 2
      lazy = Moduler::Lazy::Value.new(false) { 100 }
      expect(type.to_raw(lazy)).to eq lazy
    end
  end

  context "default" do
    it "When no default is specified, nil is returned" do
      expect(type.default).to eq nil
    end

    it "When a default is specified, it is returned" do
      type.default = 100
      expect(type.default).to eq 100
    end

    it "When a default is specified, coercers are run" do
      type = MultiplyCoercer.new in_val: 2, out_val: 3
      type.default = 100
      expect(type.default).to eq 600
    end

    it "When a lazy default is specified, it is returned" do
      type.default = Moduler::Lazy::Value.new { 100 }
      expect(type.default).to eq 100
    end

    it "When a caching lazy default is specified, coercers are run" do
      run = 0
      type = MultiplyCoercer.new in_val: 2, out_val: 3
      type.default = Moduler::Lazy::Value.new(true) { run += 1; 100 }
      expect(type.default).to eq 600
      expect(type.default).to eq 600
      expect(run).to eq 1
    end

    it "When a non-caching lazy default is specified, it is cached and returned" do
      run = 0
      type = MultiplyCoercer.new in_val: 2, out_val: 3
      type.default = Moduler::Lazy::Value.new { run += 1; 100 }

      expect(type.default).to eq 600
      expect(type.default).to eq 600
      expect(run).to eq 2
    end
  end

  describe "from_raw" do
    it "By default, from_raw returns the input value" do
      expect(type.from_raw(100)).to eq 100
      expect(type.from_raw(nil)).to be_nil
    end

    it "When a from_raw is specified, it is called" do
      type = MultiplyCoercer.new out_val: 2
      expect(type.from_raw(100)).to eq 200
    end

    context "Lazy value" do
      it "When given a caching lazy value, the value is returned and cached" do
        run = 0
        value = Moduler::Lazy::Value.new(true) { run += 1; 100 }
        expect(type.from_raw(value)).to eq 100
        expect(type.from_raw(value)).to eq 100
        expect(run).to eq 1
      end

      it "When given a non-caching lazy value, the value is returned and not cached" do
        run = 0
        value = Moduler::Lazy::Value.new { run += 1; 100 }
        expect(type.from_raw(value)).to eq 100
        expect(type.from_raw(value)).to eq 100
        expect(run).to eq 2
      end

      it "When given a caching lazy value, both coercers and out coercers are run" do
        type = MultiplyCoercer.new in_val: 6, out_val: 35
        run = 0
        value = Moduler::Lazy::Value.new(true) { run += 1; 100 }
        expect(type.from_raw(value)).to eq 21000
        expect(type.from_raw(value)).to eq 21000
        expect(run).to eq 1
      end

      it "When given a non-caching lazy value, both coercers and out coercers are run" do
        type = MultiplyCoercer.new in_val: 6, out_val: 35
        run = 0
        value = Moduler::Lazy::Value.new { run += 1; 100 }
        expect(type.from_raw(value)).to eq 21000
        expect(type.from_raw(value)).to eq 21000
        expect(run).to eq 2
      end
    end
  end
  describe "construct_raw" do
    it "type.construct_raw() sets the value" do
      expect(type.construct_raw(100)).to eq 100
    end

    it "type.construct_raw() runs coercers but not coercers_out" do
      type = MultiplyCoercer.new in_val: 2, out_val: 3
      expect(type.construct_raw(100)).to eq 200
    end

    it "type.construct_raw() sets the value to the block" do
      block = proc { 100 }
      expect(type.construct_raw(&block)).to eq block
    end

    it "type.construct_raw() with block calls coercers but not coercers_out" do
      block = proc { 100 }
      type = MultiplyCoercer.new in_val: 2, out_val: 3
      expect(type.construct_raw(&block).call).to eq 200
    end
  end
end
