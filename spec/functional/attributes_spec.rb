require 'moduler'

module TestRoot
end

describe Moduler::DSL::DSL, :focus do
  let :m do
    TestRoot.const_set(:M, Module.new)
  end
  let :moduler do
    Moduler::DSL::DSL.new(target: m)
  end

  context "When a module has attribute :x" do
    before :each do
      moduler.class_level.attribute :x
    end

    it "Can get and set x" do
      expect(m.x).to be_nil
      m.x = 10
      expect(m.x).to eq 10
      m.x 20
      expect(m.x).to eq 20
      m.x { 30 }
      expect(m.x.call).to eq 30
    end
  end

  context "When a module attribute :x has a guard" do
    before :each do
      moduler.class_level.attribute :x, moduler.kind_of([Symbol, String])
    end

    it "Can get and set x" do
      expect(m.x).to be_nil
      m.x = 10
      expect(m.x).to eq 10
      m.x 20
      expect(m.x).to eq 20
      m.x { 30 }
      expect(m.x.call).to eq 30
    end
  end
end
