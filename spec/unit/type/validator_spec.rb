require 'support/spec_support'
require 'moduler/type'
require 'moduler/errors'

describe Moduler::Type do
  let(:type) { Moduler::Type.new }

  context "With cannot_be(:nil,:frozen,:terrible)" do
    before { type.cannot_be [:nil,:frozen,:terrible] }
    it "'hi' matches" do
      expect(type.coerce('hi', nil)).to eq 'hi'
    end
    it "frozen 'hi' does not match" do
      s = 'hi'
      s.freeze
      expect { type.coerce(s, nil) }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil does not match" do
      expect { type.coerce(nil, nil) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With equal_to(1,2,nil)" do
    before { type.equal_to [1,2,nil] }
    it "1 matches" do
      expect(type.coerce(1, nil)).to eq 1
    end
    it "2 matches" do
      expect(type.coerce(2, nil)).to eq 2
    end
    it "nil matches" do
      expect(type.coerce(nil, nil)).to be_nil
    end
    it "3 does not match" do
      expect { type.coerce(3, nil) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With kind_of(Symbol,String,NilClass)" do
    before { type.kind_of [ Symbol,String,NilClass ] }
    it "'1' matches" do
      expect(type.coerce('1', nil)).to eq '1'
    end
    it ":a matches" do
      expect(type.coerce(:a, nil)).to eq :a
    end
    it "nil matches" do
      expect(type.coerce(nil, nil)).to be_nil
    end
    it "3 does not match" do
      expect { type.coerce(3, nil) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With regexes('a*b', /c*d$/)" do
    before { type.regexes [ 'a*b', /c*d$/ ] }
    it "'aaaaab' matches" do
      expect(type.coerce('aaaaab', nil)).to eq 'aaaaab'
    end
    it "'aaaaabe' matches" do
      expect(type.coerce('aaaaabe', nil)).to eq 'aaaaabe'
    end
    it "cccccccd matches" do
      expect(type.coerce('cccccccd', nil)).to eq 'cccccccd'
    end
    it "cccccccde does not match" do
      expect { type.coerce('cccccccde', nil) }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil matches" do
      expect(type.coerce(nil, nil)).to be_nil
    end
    it "3 does not match" do
      expect { type.coerce(3, nil) }.to raise_error(Moduler::ValidationFailed)
    end
    it "Object.new does not match" do
      expect { type.coerce(Object.new, nil) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With respond_to(:pop, 'abs')" do
    before { type.respond_to [:include?,'size'] }
    it "[1,2] matches" do
      expect(type.coerce([1,2], nil)).to eq [1,2]
    end
    it "'hi' matches" do
      expect(type.coerce('hi', nil)).to eq 'hi'
    end
    it "1 does not match" do
      expect { type.coerce(1, nil) }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil matches" do
      expect(type.coerce(nil, nil)).to be_nil
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
      expect { type.coerce(type.target.new, nil) }.to raise_error(Moduler::ValidationFailed)
    end
    it "a required field set to a value does not yield an error" do
      expect(type.coerce(type.target.new({ :a => 1 }), nil).a).to eq 1
    end
    it "a required field set explicitly to nil yields no error" do
      expect(type.coerce(type.target.new({:a => nil}), nil).a).to be_nil
    end
  end

  context "validate procs" do
    context "With a validator proc that returns true or false" do
      before { type.validators { |v| v >= 2 } }
      it "2 matches" do
        expect(type.coerce(2, nil)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1, nil) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns a failure string" do
      before do
        type.validators do |v|
          v < 2 ? "Proc failed!" : nil
        end
      end
      it "2 matches" do
        expect(type.coerce(2, nil)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1, nil) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns an array of failure string" do
      before do
        type.validators do |v|
          v < 2 ? [ "Proc failed!" ] : []
        end
      end
      it "2 matches" do
        expect(type.coerce(2, nil)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1, nil) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns a failure" do
      before do
        type.validators { |v| "Proc failed!" if v < 2 }
      end
      it "2 matches" do
        expect(type.coerce(2, nil)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1, nil) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns an array of failures" do
      before do
        type.validators { |v| "Proc failed!" if v < 2 }
      end
      it "2 matches" do
        expect(type.coerce(2, nil)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1, nil) }.to raise_error(Moduler::ValidationFailed)
      end
    end
  end
end
