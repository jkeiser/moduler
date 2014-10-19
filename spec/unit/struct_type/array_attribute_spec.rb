require 'support/spec_support'
require 'moduler'

module ArrayAttributeTests
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

  context "With a struct class" do
    def make_struct_class(&block)
      ArrayAttributeTests.module_eval do
        @num += 1
        Moduler.struct("Test#{@num}") { instance_eval(&block) }
        const_get("Test#{@num}")
      end
    end

    let(:struct) do
      struct_class.new
    end

    context "with an array attribute" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Array
        end
      end

      it "Defaults to empty array" do
        expect(struct.foo).to eq []
      end

      it ".foo = [ 10 ] setter works" do
        expect(struct.foo = [ 10 ]).to eq [ 10 ]
        expect(struct.foo).to eq [ 10 ]
      end

      it ".foo [ 10 ] setter works" do
        expect(struct.foo [ 10 ]).to eq [ 10 ]
        expect(struct.foo).to eq [ 10 ]
      end

      it ".foo 10, 20, 30 works" do
        expect(struct.foo 10, 20, 30).to eq [10,20,30]
      end

      it ".foo = 10 throws an exception" do
        expect(struct.foo = 10).to eq 10
      end

      it ".foo nil yields nil" do
        expect(struct.foo nil).to be_nil
        expect(struct.is_set?(:foo)).to be_truthy
        expect(struct.foo).to be_nil
      end

      context "when foo is not set" do
        it ".foo returns []" do
          expect(struct.foo).to eq []
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

        it "to_hash(true) returns { :foo => [] }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => [] })
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => []} returns true" do
          expect(struct == struct_class.new({ :foo => [] })).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => [ 10 ]} returns false" do
          expect(struct == struct_class.new({ :foo => [ 10 ] })).to be_falsey
        end
      end

      context "when foo is set to []" do
        before { struct.foo = [] }

        it ".foo returns []" do
          expect(struct.foo).to eq []
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns []" do
          expect(struct.reset(:foo)).to eq []
          expect(struct.is_set?(:foo)).to be_falsey
          expect(struct.foo).to eq []
        end

        it "to_hash returns { :foo => [] }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => [] })
        end

        it "to_hash(true) returns { :foo => [] }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => [] })
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => []} returns true" do
          expect(struct == struct_class.new({ :foo => [] })).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => [ 10 ]} returns false" do
          expect(struct == struct_class.new({ :foo => [ 10 ] })).to be_falsey
        end
      end

      context "when foo is set to [ 10 ]" do
        before { struct.foo = [ 10 ] }

        it ".foo is [ 10 ]" do
          expect(struct.foo).to eq [ 10 ]
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns [ 10 ]" do
          expect(struct.reset(:foo)).to eq [ 10 ]
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq []
        end

        it "to_hash returns { :foo => [ 10 ] }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => [ 10 ] })
        end

        it "to_hash(true) returns { :foo => [ 10 ] }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => [ 10 ] })
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => []} returns false" do
          expect(struct == struct_class.new({ :foo => [] })).to be_falsey
        end

        it "struct == struct{:foo => [ 10 ]} returns true" do
          expect(struct == struct_class.new({ :foo => [ 10 ] })).to be_truthy
        end
      end

      context "when foo is set to lazy { [ 10 ] }" do
        before { struct.foo = Moduler::Lazy::Value.new { [ 10 ] } }

        it ".foo is [ 10 ]" do
          expect(struct.foo).to eq [ 10 ]
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns [ 10 ]" do
          expect(struct.reset(:foo)).to eq [ 10 ]
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq []
        end

        it "to_hash returns { :foo => [ 10 ] }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => [ 10 ] })
        end

        it "to_hash(true) returns { :foo => [ 10 ] }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => [ 10 ] })
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => []} returns false" do
          expect(struct == struct_class.new({ :foo => [] })).to be_falsey
        end

        it "struct == struct{:foo => [ 10 ]} returns true" do
          expect(struct == struct_class.new({ :foo => [ 10 ] })).to be_truthy
        end
      end

      context "when foo is set to nil" do
        before { struct.foo = nil }

        it ".foo is nil" do
          expect(struct.foo).to eq nil
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns nil" do
          expect(struct.reset(:foo)).to be_nil
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq []
        end

        it "to_hash returns { :foo => nil }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => nil })
        end

        it "to_hash(true) returns { :foo => nil }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => nil })
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns true" do
          expect(struct == struct_class.new({ :foo => nil })).to be_truthy
        end

        it "struct == struct{:foo => []} returns false" do
          expect(struct == struct_class.new({ :foo => [] })).to be_falsey
        end

        it "struct == struct{:foo => [ 10 ]} returns false" do
          expect(struct == struct_class.new({ :foo => [ 10 ] })).to be_falsey
        end
      end
    end
  end
end
