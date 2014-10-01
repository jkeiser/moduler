require 'moduler'

describe Moduler::DSL::DSL do
  let :m do
    Module.new
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
#      moduler.class_level.dsl_eval do
#        attribute :x, kind_of([Symbol, String])
#      end
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
