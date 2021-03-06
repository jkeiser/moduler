require 'support/spec_support'
require 'moduler'

module ArrayAttributeTests
  @num = 0
end

describe Moduler do
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

      it "Default array doesn't affect is_set" do
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.foo).to eq []
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end

      it "Default array appenders and such *do* affect is_set" do
        expect(struct.foo << 10).to eq [10]
        expect(struct.is_set?(:foo)).to be_truthy
        expect(struct.to_hash).to eq({foo: [10]})
      end

      it ".foo = [ 10 ] setter works" do
        expect(struct.foo = [ 10 ]).to eq [ 10 ]
        expect(struct.foo).to eq [ 10 ]
      end

      it ".foo [ 10 ] setter works" do
        struct.foo [ 10 ]
        expect(struct.foo).to eq [ 10 ]
      end

      it ".foo 10, 20, 30 works" do
        struct.foo 10, 20, 30
      end

      it ".foo = 10 yields [ 10 ]" do
        expect(struct.foo = 10).to eq 10
        expect(struct.foo).to eq [10]
      end

      it ".foo nil yields nil" do
        struct.foo nil
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
        before { struct.foo = Moduler::Value::Lazy.new { [ 10 ] } }

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

    context "Nested attributes" do

      context "And an Array[Array] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Array[Array]
          end
        end

        it "Defaults to empty array" do
          expect(struct.foo).to eq []
        end

        it ".foo = [ [ 10 ] ] setter works" do
          expect(struct.foo = [[ 10 ]]).to eq [[ 10 ]]
          expect(struct.foo).to eq [[ 10 ]]
        end

        it ".foo = [ 10 ] setter yields [ [ 10 ] ]" do
          expect(struct.foo = [ 10 ]).to eq [ 10 ]
          expect(struct.foo).to eq [[ 10 ]]
        end

        it ".foo = 10 setter yields [ [ 10 ] ]" do
          expect(struct.foo = 10).to eq 10
          expect(struct.foo).to eq [[ 10 ]]
        end

        it ".foo [ [ 10 ] ] setter works" do
          struct.foo [ 10 ]
          expect(struct.foo).to eq [[ 10 ]]
        end

        it ".foo [ 10 ], [ 20 ], [ 30 ] yields [[10],[20],[30]]" do
          struct.foo [10], [20], [30]
        end

        it ".foo [ 10, 20, 30 ] yields [[10],[20],[30]]" do
          struct.foo [ 10, 20, 30 ]
        end

        it ".foo 10, 20, 30 yields [[10],[20],[30]]" do
          struct.foo 10, 20, 30
        end

        it ".foo nil yields nil" do
          struct.foo nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end

      context "And an Array[Hash] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Array[Hash]
          end
        end

        it "Defaults to empty array" do
          expect(struct.foo).to eq []
        end

        it ".foo = [ {a: 1} ] setter works" do
          expect(struct.foo = [{a: 1}]).to eq [{a: 1}]
          expect(struct.foo).to eq [{a: 1}]
        end

        it ".foo = {a: 1} setter raises an error" do
          expect { struct.foo = {a: 1} }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo = [ 10 ] setter raises an error" do
          expect { struct.foo = [ 10 ] }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo [ {a: 1} ] setter works" do
          struct.foo([{a: 1}])
          expect(struct.foo).to eq [{a: 1}]
        end

        it ".foo {a: 1} setter raises an error" do
          expect { struct.foo = {a: 1} }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo [ {a: 1} ], [ { b: 1 } ], [ {c: 1} ] raises an exception" do
          expect { struct.foo [{a: 1}], [{b: 1}], [{c: 1}] }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo [ {a: 1}, {b: 1}, {c: 1} ] works" do
          struct.foo [ {a: 1}, {b: 1}, {c: 1} ]
        end

        it ".foo {a: 1}, {b: 1}, {c: 1} yields [{a: 1}, {b: 1}, {c: 1}]" do
          struct.foo({a: 1}, {b: 1}, {c: 1})
        end

        it ".foo nil yields nil" do
          struct.foo nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end

      context "And an Array[Set] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Array[Set]
          end
        end

        it "Defaults to empty array" do
          expect(struct.foo).to eq []
        end

        it ".foo = [ Set[10] ] setter works" do
          expect(struct.foo = [Set[10]]).to eq [Set[10]]
          expect(struct.foo).to eq [Set[10]]
        end

        it ".foo = Set[10] setter yields [ Set[10] ]" do
          expect(struct.foo = Set[10]).to eq Set[10]
          expect(struct.foo).to eq [Set[10]]
        end

        it ".foo = 10 setter yields [ Set[10] ]" do
          expect(struct.foo = 10).to eq 10
          expect(struct.foo).to eq [Set[10]]
        end

        it ".foo [ Set[10] ] setter works" do
          struct.foo Set[10]
          expect(struct.foo).to eq [Set[10]]
        end

        it ".foo Set[10], Set[20], Set[30] raises an exception" do
          struct.foo Set[10], Set[20], Set[30]
        end

        it ".foo [ 10, 20, 30 ] yields [Set[10],Set[20],Set[30]]" do
          struct.foo [ 10, 20, 30 ]
        end

        it ".foo 10, 20, 30 yields [Set[10],Set[20],Set[30]]" do
          struct.foo 10, 20, 30
        end

        it ".foo nil yields nil" do
          struct.foo nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end
    end

    context "With an array attribute defaulting to [10]" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Array, :default => [10]
        end
      end

      it "Calculating the size of the array does not affect is_set?" do
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.foo.size).to eq 1
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end

      it "Retrieving a frozen, raw value from a default array does not affect is_set", :pending => RUBY_VERSION.to_f < 2.0 do
        expect(struct.foo[0]).to eq 10
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end
    end

    context "With an array attribute defaulting to ['hi']" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Array, :default => ['hi']
        end
      end

      it "Calculating the size of the array does not affect is_set?" do
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.foo.size).to eq 1
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end

      it "Retrieving a non-frozen, raw value from a default array *does* affect is_set" do
        x = struct.foo[0]
        expect(x).to eq 'hi'
        expect(struct.is_set?(:foo)).to be_truthy
        x << ' you'
        expect(struct.to_hash).to eq({foo: ['hi you']})
      end
    end
  end
end
