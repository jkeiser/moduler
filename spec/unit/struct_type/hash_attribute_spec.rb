require 'support/spec_support'
require 'moduler'

module HashAttributeTests
  @num = 0
end

describe Moduler do
  context "With a struct class" do
    def make_struct_class(&block)
      HashAttributeTests.module_eval do
        @num += 1
        Moduler.struct("Test#{@num}") { instance_eval(&block) }
        const_get("Test#{@num}")
      end
    end

    let(:struct) do
      struct_class.new
    end

    context "with a hash attribute" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Hash
        end
      end

      it "Defaults to empty hash" do
        expect(struct.foo).to eq({})
      end

      it "Default hash doesn't affect is_set" do
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.foo).to eq({})
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end

      it "Default hash modifiers *do* affect is_set" do
        expect(struct.foo[:bar] = 10).to eq 10
        expect(struct.is_set?(:foo)).to be_truthy
        expect(struct.to_hash).to eq({foo: {bar: 10}})
      end

      it ".foo = { :a => 1 } setter works" do
        expect(struct.foo = { :a => 1 }).to eq({ :a => 1 })
        expect(struct.foo).to eq({ :a => 1 })
      end

      it ".foo :a => 1 setter works" do
        expect(struct.foo :a => 1).to eq({ :a => 1 })
        expect(struct.foo).to eq({ :a => 1 })
      end

      it ".foo { :a => 1 }, { :b => 2 } raises an error" do
        expect { struct.foo({ :a => 1 }, { :b => 2 }) }.to raise_error { ArgumentError }
      end

      it ".foo = 10 throws an exception" do
        expect { struct.foo = 10 }.to raise_error(Moduler::ValidationFailed)
      end

      it ".foo nil yields nil" do
        expect(struct.foo nil).to be_nil
        expect(struct.is_set?(:foo)).to be_truthy
        expect(struct.foo).to be_nil
      end

      context "when foo is not set" do
        it ".foo returns {}" do
          expect(struct.foo).to eq({})
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

        it "to_hash(true) returns { :foo => {} }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => {} })
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => {}} returns true" do
          expect(struct == struct_class.new({ :foo => {} })).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => { :a => 1 }} returns false" do
          expect(struct == struct_class.new({ :foo => { :a => 1 } })).to be_falsey
        end
      end

      context "when foo is set to {}" do
        before { struct.foo = {} }

        it ".foo returns {}" do
          expect(struct.foo).to eq({})
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns {}" do
          expect(struct.reset(:foo)).to eq({})
          expect(struct.is_set?(:foo)).to be_falsey
          expect(struct.foo).to eq({})
        end

        it "to_hash returns { :foo => {} }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => {} })
        end

        it "to_hash(true) returns { :foo => {} }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => {} })
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => {}} returns true" do
          expect(struct == struct_class.new({ :foo => {} })).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => { :a => 1 }} returns false" do
          expect(struct == struct_class.new({ :foo => { :a => 1 } })).to be_falsey
        end
      end

      context "when foo is set to { :a => 1 }" do
        before { struct.foo = { :a => 1 } }

        it ".foo is { :a => 1 }" do
          expect(struct.foo).to eq({ :a => 1 })
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns { :a => 1 }" do
          expect(struct.reset(:foo)).to eq({ :a => 1 })
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq({})
        end

        it "to_hash returns { :foo => { :a => 1 } }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => { :a => 1 } })
        end

        it "to_hash(true) returns { :foo => { :a => 1 } }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => { :a => 1 } })
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => {}} returns false" do
          expect(struct == struct_class.new({ :foo => {} })).to be_falsey
        end

        it "struct == struct{:foo => { :a => 1 }} returns true" do
          expect(struct == struct_class.new({ :foo => { :a => 1 } })).to be_truthy
        end
      end

      context "when foo is set to lazy { { :a => 1 } }" do
        before { struct.foo = Moduler::Value::Lazy.new { { :a => 1 } } }

        it ".foo is { :a => 1 }" do
          expect(struct.foo).to eq({ :a => 1 })
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns { :a => 1 }" do
          expect(struct.reset(:foo)).to eq({ :a => 1 })
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq({})
        end

        it "to_hash returns { :foo => { :a => 1 } }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => { :a => 1 } })
        end

        it "to_hash(true) returns { :foo => { :a => 1 } }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => { :a => 1 } })
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => {}} returns false" do
          expect(struct == struct_class.new({ :foo => {} })).to be_falsey
        end

        it "struct == struct{:foo => { :a => 1 }} returns true" do
          expect(struct == struct_class.new({ :foo => { :a => 1 } })).to be_truthy
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
          expect(struct.foo).to eq({})
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

        it "struct == struct{:foo => {}} returns false" do
          expect(struct == struct_class.new({ :foo => {} })).to be_falsey
        end

        it "struct == struct{:foo => { :a => 1 }} returns false" do
          expect(struct == struct_class.new({ :foo => { :a => 1 } })).to be_falsey
        end
      end
    end

    context "Nested attributes" do

      context "And a Hash[Symbol=>Hash] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Hash[Symbol=>Hash]
          end
        end

        it "Defaults to empty hash" do
          expect(struct.foo).to eq({})
        end

        it ".foo = {a: {x: 1} } setter works" do
          expect(struct.foo = {a: {x: 1}}).to eq({a: {x: 1}})
          expect(struct.foo).to eq({a: {x: 1}})
        end

        it ".foo = {x: 1} raises an error" do
          expect { struct.foo = {x: 1} }.to raise_error Moduler::ValidationFailed
        end

        it ".foo = 10 raises an error" do
          expect { struct.foo = 10 }.to raise_error Moduler::ValidationFailed
        end

        it ".foo {a: {x: 1}} setter works" do
          expect(struct.foo({a: {x: 1}})).to eq({a: {x: 1}})
          expect(struct.foo).to eq({a: {x: 1}})
        end

        it ".foo {a: {x: 1}}, {b: {x: 1}} raises an exception" do
          expect { struct.foo({a: {x: 1}}, {b: {x: 1}}) }.to raise_error ArgumentError
        end

        it ".foo nil yields nil" do
          expect(struct.foo nil).to be_nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end

      context "And a Hash[Symbol=>Array] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Hash[Symbol=>Array]
          end
        end

        it "Defaults to empty hash" do
          expect(struct.foo).to eq({})
        end

        it ".foo = {a: [10] } setter works" do
          expect(struct.foo = {a: [10]}).to eq({a: [10]})
          expect(struct.foo).to eq({a: [10]})
        end

        it ".foo = [10] raises an error" do
          expect { struct.foo = [10] }.to raise_error Moduler::ValidationFailed
        end

        it ".foo = 10 raises an error" do
          expect { struct.foo = 10 }.to raise_error Moduler::ValidationFailed
        end

        it ".foo {a: [10]} setter works" do
          expect(struct.foo({a: [10]})).to eq({a: [10]})
          expect(struct.foo).to eq({a: [10]})
        end

        it ".foo {a: [10]}, {b: [10]} raises an exception" do
          expect { struct.foo({a: [10]}, {b: [10]}) }.to raise_error ArgumentError
        end

        it ".foo nil yields nil" do
          expect(struct.foo nil).to be_nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end

      context "And a Hash[Symbol=>Set] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Hash[Symbol=>Set]
          end
        end

        it "Defaults to empty hash" do
          expect(struct.foo).to eq({})
        end

        it ".foo = {a: Set[10] } setter works" do
          expect(struct.foo = {a: Set[10]}).to eq({a: Set[10]})
          expect(struct.foo).to eq({a: Set[10]})
        end

        it ".foo = Set[10] raises an error" do
          expect { struct.foo = Set[10] }.to raise_error Moduler::ValidationFailed
        end

        it ".foo = 10 raises an error" do
          expect { struct.foo = 10 }.to raise_error Moduler::ValidationFailed
        end

        it ".foo {a: Set[10]} setter works" do
          expect(struct.foo({a: Set[10]})).to eq({a: Set[10]})
          expect(struct.foo).to eq({a: Set[10]})
        end

        it ".foo {a: Set[10]}, {b: Set[10]} raises an exception" do
          expect { struct.foo({a: Set[10]}, {b: Set[10]}) }.to raise_error ArgumentError
        end

        it ".foo nil yields nil" do
          expect(struct.foo nil).to be_nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end
    end

    context "With a hash attribute defaulting to {a: 1}" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Hash, :default => {a: 1}
        end
      end

      it "Calculating the size of the hash does not affect is_set?" do
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.foo.size).to eq 1
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end

      it "Retrieving a frozen, raw value from a default hash does not affect is_set", :pending => RUBY_VERSION.to_f < 2.0 do
        expect(struct.foo[:a]).to eq 1
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end
    end

    context "With a hash attribute defaulting to {a: 'hi'}" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Hash, :default => {a: 'hi'}
        end
      end

      it "Calculating the size of the hash does not affect is_set?" do
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.foo.size).to eq 1
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end

      it "Retrieving a non-frozen, raw value from a default hash *does* affect is_set" do
        x = struct.foo[:a]
        expect(x).to eq 'hi'
        expect(struct.is_set?(:foo)).to be_truthy
        x << ' you'
        expect(struct.to_hash).to eq({foo: {a: 'hi you'}})
      end
    end

  end
end
