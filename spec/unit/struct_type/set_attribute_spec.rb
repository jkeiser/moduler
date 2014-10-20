require 'support/spec_support'
require 'moduler'

module SetAttributeTests
  @num = 0
end

describe Moduler do
  context "With a struct class" do
    def make_struct_class(&block)
      SetAttributeTests.module_eval do
        @num += 1
        Moduler.struct("Test#{@num}") { instance_eval(&block) }
        const_get("Test#{@num}")
      end
    end

    let(:struct) do
      struct_class.new
    end

    context "with an set attribute" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Set
        end
      end

      it "Defaults to empty set" do
        expect(struct.foo).to eq Set.new
      end

      it ".foo = Set.new([ 10 ]) setter works" do
        expect(struct.foo = Set.new([ 10 ])).to eq Set.new([ 10 ])
        expect(struct.foo).to eq Set.new([ 10 ])
      end

      it ".foo Set.new([ 10 ]) setter works" do
        expect(struct.foo Set.new([ 10 ])).to eq Set.new([ 10 ])
        expect(struct.foo).to eq Set.new([ 10 ])
      end

      it ".foo 10, 20, 30 works" do
        expect(struct.foo 10, 20, 30).to eq Set.new([10,20,30])
      end

      it ".foo = 10 yield Set.new([ 10 ])" do
        expect(struct.foo = 10).to eq 10
        expect(struct.foo).to eq Set.new([ 10 ])
      end

      it ".foo nil yields nil" do
        expect(struct.foo nil).to be_nil
        expect(struct.is_set?(:foo)).to be_truthy
        expect(struct.foo).to be_nil
      end

      context "when foo is not set" do
        it ".foo returns Set.new" do
          expect(struct.foo).to eq Set.new
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

        it "to_hash(true) returns { :foo => Set.new }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => Set.new })
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => Set.new} returns true" do
          expect(struct == struct_class.new({ :foo => Set.new })).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => Set.new([ 10 ])} returns false" do
          expect(struct == struct_class.new({ :foo => Set.new([ 10 ]) })).to be_falsey
        end
      end

      context "when foo is set to Set.new" do
        before { struct.foo = Set.new }

        it ".foo returns Set.new" do
          expect(struct.foo).to eq Set.new
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns Set.new" do
          expect(struct.reset(:foo)).to eq Set.new
          expect(struct.is_set?(:foo)).to be_falsey
          expect(struct.foo).to eq Set.new
        end

        it "to_hash returns { :foo => Set.new }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => Set.new })
        end

        it "to_hash(true) returns { :foo => Set.new }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => Set.new })
        end

        it "struct == <empty struct> returns true" do
          expect(struct == struct_class.new).to be_truthy
        end

        it "struct == struct{:foo => Set.new} returns true" do
          expect(struct == struct_class.new({ :foo => Set.new })).to be_truthy
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => Set.new([ 10 ])} returns false" do
          expect(struct == struct_class.new({ :foo => Set.new([ 10 ]) })).to be_falsey
        end
      end

      context "when foo is set to Set.new([ 10 ])" do
        before { struct.foo = Set.new([ 10 ]) }

        it ".foo is Set.new([ 10 ])" do
          expect(struct.foo).to eq Set.new([ 10 ])
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns Set.new([ 10 ])" do
          expect(struct.reset(:foo)).to eq Set.new([ 10 ])
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq Set.new
        end

        it "to_hash returns { :foo => Set.new([ 10 ]) }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => Set.new([ 10 ]) })
        end

        it "to_hash(true) returns { :foo => Set.new([ 10 ]) }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => Set.new([ 10 ]) })
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => Set.new} returns false" do
          expect(struct == struct_class.new({ :foo => Set.new })).to be_falsey
        end

        it "struct == struct{:foo => Set.new([ 10 ])} returns true" do
          expect(struct == struct_class.new({ :foo => Set.new([ 10 ]) })).to be_truthy
        end
      end

      context "when foo is set to lazy { Set.new([ 10 ]) }" do
        before { struct.foo = Moduler::Lazy::Value.new { Set.new([ 10 ]) } }

        it ".foo is Set.new([ 10 ])" do
          expect(struct.foo).to eq Set.new([ 10 ])
        end

        it "is_set?(:foo) returns true" do
          expect(struct.is_set?(:foo)).to be_truthy
        end

        it "reset(:foo) returns Set.new([ 10 ])" do
          expect(struct.reset(:foo)).to eq Set.new([ 10 ])
          expect(struct.is_set?(:foo)).to eq false
          expect(struct.foo).to eq Set.new
        end

        it "to_hash returns { :foo => Set.new([ 10 ]) }" do
          expect(struct.to_hash).to be_kind_of(Hash)
          expect(struct.to_hash).to eq({ :foo => Set.new([ 10 ]) })
        end

        it "to_hash(true) returns { :foo => Set.new([ 10 ]) }" do
          expect(struct.to_hash(true)).to be_kind_of(Hash)
          expect(struct.to_hash(true)).to eq({ :foo => Set.new([ 10 ]) })
        end

        it "struct == <empty struct> returns false" do
          expect(struct == struct_class.new).to be_falsey
        end

        it "struct == struct{:foo => nil} returns false" do
          expect(struct == struct_class.new({ :foo => nil })).to be_falsey
        end

        it "struct == struct{:foo => Set.new} returns false" do
          expect(struct == struct_class.new({ :foo => Set.new })).to be_falsey
        end

        it "struct == struct{:foo => Set.new([ 10 ])} returns true" do
          expect(struct == struct_class.new({ :foo => Set.new([ 10 ]) })).to be_truthy
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
          expect(struct.foo).to eq Set.new
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

        it "struct == struct{:foo => Set.new} returns false" do
          expect(struct == struct_class.new({ :foo => Set.new })).to be_falsey
        end

        it "struct == struct{:foo => Set.new([ 10 ])} returns false" do
          expect(struct == struct_class.new({ :foo => Set.new([ 10 ]) })).to be_falsey
        end
      end
    end

    context "Nested attributes" do

      context "And a Set[Array] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Set[Array]
          end
        end

        it "Defaults to empty set" do
          expect(struct.foo).to eq Set[]
        end

        it ".foo = [ [ 10 ] ] setter works" do
          expect(struct.foo = [ [ 10 ] ]).to eq [ [ 10 ] ]
          expect(struct.foo).to eq Set[ [ 10 ] ]
        end

        it ".foo = Set[ [ 10 ] ] setter works" do
          expect(struct.foo = Set[ [ 10 ] ]).to eq Set[ [ 10 ] ]
          expect(struct.foo).to eq Set[ [ 10 ] ]
        end

        it ".foo = [ 10 ] setter yields Set[ [ 10 ] ]" do
          expect(struct.foo = [ 10 ]).to eq [ 10 ]
          expect(struct.foo).to eq Set[ [ 10 ] ]
        end

        it ".foo = 10 setter yields Set[ [ 10 ] ]" do
          expect(struct.foo = 10).to eq 10
          expect(struct.foo).to eq Set[ [ 10 ] ]
        end

        it ".foo [ [ 10 ] ] setter works" do
          expect(struct.foo [ [ 10 ] ]).to eq Set[ [ 10 ] ]
          expect(struct.foo).to eq Set[ [ 10 ] ]
        end

        it ".foo Set[ [ 10 ] ] setter works" do
          expect(struct.foo Set[ [ 10 ] ]).to eq Set[ [ 10 ] ]
          expect(struct.foo).to eq Set[ [ 10 ] ]
        end

        it ".foo [ 10 ], [ 20 ], [ 30 ] yields Set[[10],[20],[30]]" do
          expect(struct.foo [10], [20], [30]).to eq Set[[10],[20],[30]]
        end

        it ".foo [ 10, 20, 30 ] yields Set[[10],[20],[30]]" do
          expect(struct.foo [ 10, 20, 30 ]).to eq Set[[10],[20],[30]]
        end

        it ".foo 10, 20, 30 yields Set[[10],[20],[30]]" do
          expect(struct.foo 10, 20, 30).to eq Set[[10], [20], [30]]
        end

        it ".foo nil yields nil" do
          expect(struct.foo nil).to be_nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end

      context "And a Set[Hash] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Set[Hash]
          end
        end

        it "Defaults to empty set" do
          expect(struct.foo).to eq Set[]
        end

        it ".foo = [ {a: 1} ] setter works" do
          expect(struct.foo = [{a: 1}]).to eq [{a: 1}]
          expect(struct.foo).to eq Set[{a: 1}]
        end

        it ".foo = {a: 1} setter raises an error" do
          expect { struct.foo = {a: 1} }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo = [ 10 ] setter raises an error" do
          expect { struct.foo = [ 10 ] }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo [ {a: 1} ] setter works" do
          expect(struct.foo([{a: 1}])).to eq Set[{a: 1}]
          expect(struct.foo).to eq Set[{a: 1}]
        end

        it ".foo {a: 1} setter raises an error" do
          expect { struct.foo = {a: 1} }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo [ {a: 1} ], [ { b: 1 } ], [ {c: 1} ] raises an error" do
          expect { struct.foo [{a: 1}], [{b: 1}], [{c: 1}] }.to raise_error(Moduler::ValidationFailed)
        end

        it ".foo [ {a: 1}, {b: 1}, {c: 1} ] works" do
          expect(struct.foo [ {a: 1}, {b: 1}, {c: 1} ]).to eq Set[{a: 1}, {b: 1}, {c: 1}]
        end

        it ".foo {a: 1}, {b: 1}, {c: 1} yields Set[{a: 1}, {b: 1}, {c: 1}]" do
          expect(struct.foo({a: 1}, {b: 1}, {c: 1})).to eq Set[{a: 1}, {b: 1}, {c: 1}]
        end

        it ".foo nil yields nil" do
          expect(struct.foo nil).to be_nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end

      context "And a Set[Set] attribute" do
        let(:struct_class) do
          make_struct_class do
            attribute :foo, Set[Set]
          end
        end

        it "Defaults to empty set" do
          expect(struct.foo).to eq Set[]
        end

        it ".foo = [ [10] ] setter works" do
          expect(struct.foo = [[10]]).to eq [[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo = [ Set[10] ] setter works" do
          expect(struct.foo = [Set[10]]).to eq [Set[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo = Set[ [10] ] setter works" do
          expect(struct.foo = Set[[10]]).to eq Set[[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo = Set[ Set[10] ] setter works" do
          expect(struct.foo = Set[Set[10]]).to eq Set[Set[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo = Set[10] setter yields Set[ Set[10] ]" do
          expect(struct.foo = Set[10]).to eq Set[10]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo = 10 setter yields Set[ Set[10] ]" do
          expect(struct.foo = 10).to eq 10
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo [ [10] ] setter works" do
          expect(struct.foo [[10]]).to eq Set[Set[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo [ Set[10] ] setter works" do
          expect(struct.foo [Set[10]]).to eq Set[Set[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo Set[ [10] ] setter works" do
          expect(struct.foo Set[[10]]).to eq Set[Set[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo Set[ Set[10] ] setter works" do
          expect(struct.foo Set[Set[10]]).to eq Set[Set[10]]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo Set[10] setter yields Set[ Set[10] ]" do
          expect(struct.foo Set[10]).to eq Set[ Set[10] ]
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo 10 setter yields Set[ Set[10] ]" do
          expect(struct.foo = 10).to eq 10
          expect(struct.foo).to eq Set[Set[10]]
        end

        it ".foo Set[10], [20], Set[30] yields Set[Set[10], Set[20], Set[30]]" do
          expect(struct.foo Set[10], Set[20], Set[30]).to eq Set[Set[10],Set[20],Set[30]]
        end

        it ".foo [ 10, 20, 30 ] yields Set[Set[10],Set[20],Set[30]]" do
          expect(struct.foo [ 10, 20, 30 ]).to eq Set[Set[10],Set[20],Set[30]]
        end

        it ".foo Set[ 10, 20, 30 ] yields Set[Set[10],Set[20],Set[30]]" do
          expect(struct.foo [ 10, 20, 30 ]).to eq Set[Set[10],Set[20],Set[30]]
        end

        it ".foo 10, 20, 30 yields Set[Set[10],Set[20],Set[30]]" do
          expect(struct.foo 10, 20, 30).to eq Set[Set[10], Set[20], Set[30]]
        end

        it ".foo nil yields nil" do
          expect(struct.foo nil).to be_nil
          expect(struct.is_set?(:foo)).to be_truthy
          expect(struct.foo).to be_nil
        end
      end
    end
  end
end
