require 'support/spec_support'
require 'moduler'

module DSLTests
  @num = 0
end

describe Moduler do
  # Works in:
  # - a module
  # - a class
  # - a module or class with an initializer
  # -
  # Supports:
  # - hashes in everything
  # - singular form
  # - validators
  # - setters
  # - call_proc
  # - specialize_from

  context "With a class" do
    def make_struct_class(&block)
      DSLTests.module_eval do
        @num += 1
        Moduler.struct("Test#{@num}") { instance_eval(&block) }
        const_get("Test#{@num}")
      end
    end

    let(:struct) do
      struct_class.new
    end

    context "with no attributes" do
      let(:struct_class) do
        make_struct_class do
        end
      end

      it ".foo returns a variable not defined error" do
        expect { struct.foo }.to raise_error(NoMethodError)
      end

      it "instance_eval { foo } returns a local variable missing error (not method missing)" do
        expect { struct.instance_eval { foo } }.to raise_error(NameError)
      end

      it "== struct.new returns true" do
        expect(struct == struct_class.new).to be_truthy
      end

      it "== {} returns false" do
        expect(struct == {}).to be_falsey
      end

      it ".is_set?(:foo) returns false" do
        expect(struct.is_set?(:foo)).to be_falsey
      end

      it ".reset(:foo) succeeds" do
        expect(struct.reset(:foo)).to be_nil
      end

      it ".to_hash returns {}" do
        expect(struct.to_hash).to eq({})
      end

      it ".to_hash(true) returns {}" do
        expect(struct.to_hash(true)).to eq({})
      end
    end

    # TODO lazy default
    # TODO lazy value set
    context "with a basic attribute with no type" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo
        end
      end

      it "Defaults to nil" do
        expect(struct.foo).to be_nil
      end

      it ".foo = <value> setter works" do
        expect(struct.foo = 10).to eq 10
        expect(struct.foo).to eq 10
      end

      it ".foo <value> setter works" do
        expect(struct.foo 10).to eq 10
        expect(struct.foo).to eq 10
      end

      it ".foo { <proc> } setter works" do
        expect(struct.foo { 10 }).to be_kind_of(Proc)
        expect(struct.foo.call).to eq 10
      end

      context "when foo is not set" do
        it ".foo returns nil" do
          expect(struct.foo).to be_nil
        end

        it "is_set?(:foo) returns false" do
          expect(struct.is_set?(:foo)).to eq false
        end

        it "reset(:foo) returns nil" do
          expect(struct.reset(:foo)).to be_nil
        end

        it "to_hash returns {}" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({})
        end

        it "to_hash(true) returns { :foo => nil }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => nil })
        end

        it "struct == {} returns false" do
          expect(struct == {}).to be_falsey
        end

        it "struct == { :foo => nil } returns false" do
          expect(struct == { :foo => nil }).to be_falsey
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => nil} returns true" do
          expect(struct == struct_class.new({ :foo => nil })).to be_truthy
        end

        it "struct == { :foo => 10 } returns false" do
          expect(struct == { :foo => 10 }).to be_falsey
        end

        it "struct == { :bar => 10 } returns false" do
          expect(struct == { :bar => 10 }).to be_falsey
        end
      end

      context "when foo is set to nil" do
        before { struct.foo = nil }

        it ".foo is nil" do
          expect(struct.foo).to be_nil
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns nil" do
          expect(struct.reset(:foo)).to be_nil
          expect(struct.is_set?(:foo)).to be_falsey
          expect(struct.foo).to be_nil
        end

        it "to_hash returns { :foo => nil }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => nil })
        end

        it "to_hash(true) returns { :foo => nil }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => nil })
        end

        it "struct == {} returns false" do
          expect(struct == {}).to be_falsey
        end

        it "struct == { :foo => nil } returns false" do
          expect(struct == { :foo => nil }).to be_falsey
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => nil} returns true" do
          expect(struct == struct_class.new({ :foo => nil })).to be_truthy
        end

        it "struct == struct{:foo => 10} returns false" do
          expect(struct == struct_class.new({ :foo => 10 })).to be_falsey
        end
      end

      context "when foo is set to 10" do
        before { struct.foo = 10 }

        it ".foo is 10" do
          expect(struct.foo).to eq 10
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns 10" do
          expect(struct.reset(:foo)).to eq 10
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to be_nil
        end

        it "to_hash returns { :foo => 10 }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => 10 })
        end

        it "to_hash(true) returns { :foo => 10 }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => 10 })
        end

        it "struct == {} returns false" do
          expect(struct == {}).to be_falsey
        end

        it "struct == { :foo => nil } returns false" do
          expect(struct == { :foo => nil }).to be_falsey
        end

        it "struct == { :foo => 10 } returns false" do
          expect(struct == { :foo => 10 }).to be_falsey
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => 10} returns 10" do
          expect(struct == struct_class.new({ :foo => 10 })).to be_truthy
        end
      end

      context "when foo is set to lazy { 10 }" do
        before { struct.foo = Moduler::Lazy::Value.new { 10 } }

        it ".foo is 10" do
          expect(struct.foo).to eq 10
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns 10" do
          expect(struct.reset(:foo)).to eq 10
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to be_nil
        end

        it "to_hash returns { :foo => 10 }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => 10 })
        end

        it "to_hash(true) returns { :foo => 10 }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => 10 })
        end

        it "struct == {} returns false" do
          expect(struct == {}).to be_falsey
        end

        it "struct == { :foo => nil } returns false" do
          expect(struct == { :foo => nil }).to be_falsey
        end

        it "struct == { :foo => 10 } returns false" do
          expect(struct == { :foo => 10 }).to be_falsey
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => 10} returns 10" do
          expect(struct == struct_class.new({ :foo => 10 })).to be_truthy
        end
      end
    end

    context "with a basic attribute with a default of 10" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, :default => 10
        end
      end

      it ".foo = <value> setter works" do
        expect(struct.foo = 10).to eq 10
        expect(struct.foo).to eq 10
      end

      it ".foo <value> setter works" do
        expect(struct.foo 10).to eq 10
        expect(struct.foo).to eq 10
      end

      it ".foo { <proc> } setter works" do
        expect(struct.foo { 10 }).to be_kind_of(Proc)
        expect(struct.foo.call).to eq 10
      end

      context "when foo is not set" do
        it ".foo is 10" do
          expect(struct.foo).to eq 10
        end

        it "is_set?(:foo) returns false" do
          expect(struct.is_set?(:foo)).to be_falsey
        end

        it "reset(:foo) returns nil" do
          expect(struct.reset(:foo)).to eq nil
          expect(struct.foo).to eq 10
        end

        it "to_hash returns {}" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({})
        end

        it "to_hash(true) returns { :foo => 10 }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => 10 })
        end

        it "struct == {} returns false" do
          expect(struct == {}).to be_falsey
        end

        it "struct == { :foo => nil } returns false" do
          expect(struct == { :foo => nil }).to be_falsey
        end

        it "struct == { :foo => 10 } returns false" do
          expect(struct == { :foo => 10 }).to be_falsey
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => 10} returns 10" do
          expect(struct == struct_class.new({ :foo => 10 })).to be_truthy
        end
      end

      context "when foo is set to nil" do
        before { struct.foo = nil }

        it ".foo is nil" do
          expect(struct.foo).to be_nil
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns nil" do
          expect(struct.reset(:foo)).to be_nil
          expect(struct.is_set?(:foo)).to be_falsey
          expect(struct.foo).to eq 10
        end

        it "to_hash returns { :foo => nil }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => nil })
        end

        it "to_hash(true) returns { :foo => nil }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => nil })
        end

        it "struct == {} returns false" do
          expect(struct == {}).to be_falsey
        end

        it "struct == { :foo => nil } returns false" do
          expect(struct == { :foo => nil }).to be_falsey
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns true" do
          expect(struct == struct_class.new({ :foo => nil })).to be_truthy
        end

        it "struct == struct{:foo => 10} returns false" do
          expect(struct == struct_class.new({ :foo => 10 })).to be_falsey
        end
      end

      context "when foo is set to 10" do
        before { struct.foo = 10 }

        it ".foo is 10" do
          expect(struct.foo).to eq 10
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns 10" do
          expect(struct.reset(:foo)).to eq 10
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq 10
        end

        it "to_hash returns { :foo => 10 }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => 10 })
        end

        it "to_hash(true) returns { :foo => 10 }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => 10 })
        end

        it "struct == {} returns false" do
          expect(struct == {}).to be_falsey
        end

        it "struct == { :foo => nil } returns false" do
          expect(struct == { :foo => nil }).to be_falsey
        end

        it "struct == { :foo => 10 } returns false" do
          expect(struct == { :foo => 10 }).to be_falsey
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => 10} returns false" do
          expect(struct == struct_class.new({ :foo => 10 })).to be_truthy
        end
      end
    end
  end
end
