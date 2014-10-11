require 'support/spec_support'
require 'moduler/type_dsl'
require 'moduler/validation/validator/cannot_be'
require 'moduler/validation/validator/equal_to'
require 'moduler/validation/validator/kind_of'
require 'moduler/validation/validator/regexes'
require 'moduler/validation/validator/required_fields'
require 'moduler/validation/validator/respond_to'
require 'moduler/validation/validator/validate_proc'
require 'moduler/errors'

describe Moduler::Validation::Validator do
  let(:type_system) { Moduler::TypeDSL.type_system }
  let(:type) { type_system.base_type.specialize }

  context "With cannot_be(:nil,:frozen,:terrible)" do
    before { type.validator = Moduler::Validation::Validator::CannotBe.new(:nil,:frozen,:terrible) }
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
    before { type.validator = Moduler::Validation::Validator::EqualTo.new(1,2,nil) }
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
    before { type.validator = Moduler::Validation::Validator::KindOf.new(Symbol,String,NilClass) }
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
    before { type.validator = Moduler::Validation::Validator::Regexes.new('a*b', /c*d$/) }
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
    it "nil does not match" do
      expect { type.coerce(nil) }.to raise_error(Moduler::ValidationFailed)
    end
    it "3 does not match" do
      expect { type.coerce(3) }.to raise_error(Moduler::ValidationFailed)
    end
    it "Object.new does not match" do
      expect { type.coerce(Object.new) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With respond_to(:pop, 'abs')" do
    before { type.validator = Moduler::Validation::Validator::RespondTo.new(:include?,'size') }
    it "[1,2] matches" do
      expect(type.coerce([1,2])).to eq [1,2]
    end
    it "'hi' matches" do
      expect(type.coerce('hi')).to eq 'hi'
    end
    it "1 does not match" do
      expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil does not match" do
      expect { type.coerce(nil) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "With required_fields('a', :b, 3, nil)" do
    before { type.validator = Moduler::Validation::Validator::RequiredFields.new('a', :b, 3, nil) }
    it "{'a' => 1, :b => 2, 3 => 3, nil => 4} matches" do
      expect(type.coerce({'a' => 1, :b => 2, 3 => 3, nil => 4})).
        to eq({'a' => 1, :b => 2, 3 => 3, nil => 4})
    end
    it "{'foo' => 'bar', 'a' => 1, :b => 2, 3 => 3, nil => 4} matches" do
      expect(type.coerce({'foo' => 'bar', 'a' => 1, :b => 2, 3 => 3, nil => 4})).
        to eq({'foo' => 'bar', 'a' => 1, :b => 2, 3 => 3, nil => 4})
    end
    it "{'a' => 1, 3 => 3, nil => 4} does not match" do
      expect { type.coerce({'a' => 1, 3 => 3, nil => 4}) }.to raise_error(Moduler::ValidationFailed)
    end
    it "{} does not match" do
      expect { type.coerce({}) }.to raise_error(Moduler::ValidationFailed)
    end
    it "nil does not match" do
      expect { type.coerce(nil) }.to raise_error(Moduler::ValidationFailed)
    end
    it "'a' does not match" do
      expect { type.coerce('a') }.to raise_error(Moduler::ValidationFailed)
    end
    it ":a does not match" do
      expect { type.coerce(:a) }.to raise_error(Moduler::ValidationFailed)
    end
  end

  context "validate procs" do
    context "With a validator proc that returns true or false" do
      before { type.validator = Moduler::Validation::Validator::ValidateProc.new { |v| v >= 2 } }
      it "2 matches" do
        expect(type.coerce(2)).to be 2
      end
      it "1 does not match" do
        expect { type.coerce(1) }.to raise_error(Moduler::ValidationFailed)
      end
    end

    context "With a validator proc that returns a failure string" do
      before do
        type.validator = Moduler::Validation::Validator::ValidateProc.new do |v|
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
        type.validator = Moduler::Validation::Validator::ValidateProc.new do |v|
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
        type.validator = Moduler::Validation::Validator::ValidateProc.new do |v|
          v < 2 ? Moduler::Validation::Validator.validation_failure(v, "Proc failed!") : nil
        end
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
        type.validator = Moduler::Validation::Validator::ValidateProc.new do |v|
          v < 2 ? [ Moduler::Validation::Validator.validation_failure(v, "Proc failed!") ] : []
        end
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
