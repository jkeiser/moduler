require 'support/spec_support'
require 'moduler/type'
require 'moduler/errors'

describe Moduler::Type do
  let(:type) { Moduler::Type.new }

  context "With cannot_be(:nil,:frozen,:terrible)" do
    before { type.cannot_be [:nil,:frozen,:terrible] }
    it "'hi' matches" do
      expect(type.coerce('hi')).to eq 'hi'
    end
    it "frozen 'hi' does not match" do
      s = 'hi'
      s.freeze
      expect { type.coerce(s) }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil does not match" do
      expect { type.coerce(nil) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With equal_to(1,2,nil)" do
    before { type.equal_to [1,2,nil] }
    it "1 matches" do
      expect(type.coerce(1)).to eq 1
    end
    it "2 matches" do
      expect(type.coerce(2)).to eq 2
    end
    it "nil matches" do
      expect(type.coerce(nil)).to be_nil
    end
    it "3 does not match" do
      expect { type.coerce(3) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With kind_of(Symbol,String,NilClass)" do
    before { type.kind_of [ Symbol,String,NilClass ] }
    it "'1' matches" do
      expect(type.coerce('1')).to eq '1'
    end
    it ":a matches" do
      expect(type.coerce(:a)).to eq :a
    end
    it "nil matches" do
      expect(type.coerce(nil)).to be_nil
    end
    it "3 does not match" do
      expect { type.coerce(3) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With regexes('a*b', /c*d$/)" do
    before { type.regexes [ 'a*b', /c*d$/ ] }
    it "'aaaaab' matches" do
      expect(type.coerce('aaaaab')).to eq 'aaaaab'
    end
    it "'aaaaabe' matches" do
      expect(type.coerce('aaaaabe')).to eq 'aaaaabe'
    end
    it "cccccccd matches" do
      expect(type.coerce('cccccccd')).to eq 'cccccccd'
    end
    it "cccccccde does not match" do
      expect { type.coerce('cccccccde') }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil matches" do
      expect(type.coerce(nil)).to be_nil
    end
    it "3 does not match" do
      expect { type.coerce(3) }.to raise_error(Moduler::ValidationFailed)
    end
    it "Object.new does not match" do
      expect { type.coerce(Object.new) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With respond_to(:pop, 'abs')" do
    before { type.respond_to [:include?,'size'] }
    it "[1,2] matches" do
      expect(type.coerce([1,2])).to eq [1,2]
    end
    it "'hi' matches" do
      expect(type.coerce('hi')).to eq 'hi'
    end
    it "1 does not match" do
      expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil matches" do
      expect(type.coerce(nil)).to be_nil
    end
  end

  context "With required fields" do
    let(:type) do
      type = Moduler::Type::StructType.new do
        target Class.new
        attribute :a, :required => true
      end
      type.emit
      type
    end
    it "a missing required field yields an error" do
      expect { type.coerce(type.target.new) }.to raise_error(Moduler::ValidationFailed)
    end
    it "a required field set to a value does not yield an error" do
      expect(type.coerce(type.target.new :a => 1).a).to eq 1
    end
    it "a required field set explicitly to nil yields no error" do
      expect(type.coerce(type.target.new :a => nil).a).to be_nil
    end
  end

  context "validate procs" do
    context "With a validator proc that returns true or false" do
      before { type.validators { |v| v >= 2 } }
      it "2 matches" do
        expect(type.coerce(2)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns a failure string" do
      before do
        type.validators do |v|
          v < 2 ? "Proc failed!" : nil
        end
      end
      it "2 matches" do
        expect(type.coerce(2)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns an array of failure string" do
      before do
        type.validators do |v|
          v < 2 ? [ "Proc failed!" ] : []
        end
      end
      it "2 matches" do
        expect(type.coerce(2)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns a failure" do
      before do
        type.validators { |v| "Proc failed!" if v < 2 }
      end
      it "2 matches" do
        expect(type.coerce(2)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns an array of failures" do
      before do
        type.validators { |v| "Proc failed!" if v < 2 }
      end
      it "2 matches" do
        expect(type.coerce(2)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
      end
    end
  end
end
