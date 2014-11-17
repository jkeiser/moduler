require 'support/spec_support'
require 'moduler'

module StructAttributeTests
  @num = 0
end

describe Moduler do
  context "With a struct class" do
    def make_struct_class(&block)
      StructAttributeTests.module_eval do
        @num += 1
        Moduler.struct("Test#{@num}") { instance_eval(&block) }
        const_get("Test#{@num}")
      end
    end

    let(:struct) do
      struct_class.new
    end

    context "with a struct attribute" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Struct do
            attribute :a
          end
        end
      end

      it "Defaults to empty struct" do
        expect(struct.foo).to eq(struct_class.new)
      end

      it "Default struct doesn't affect is_set" do
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.foo).to eq(struct_class.new)
        expect(struct.to_hash).to eq({})
        expect(struct.is_set?(:foo)).to be_falsey

        expect(struct.foo.a).to be_nil
        expect(struct.is_set?(:foo)).to be_falsey
        expect(struct.to_hash).to eq({})
      end

      it "Default hash modifiers *do* affect is_set" do
        expect(struct.foo.a = 10).to eq 10
        expect(struct.is_set?(:foo)).to be_truthy
        expect(struct.to_hash).to eq({foo: {a: 10}})
      end

      it ".foo = { :a => 1 } setter works" do
        expect(struct.foo = { :a => 1 }).to eq({ :a => 1 })
        expect(struct.foo).to eq({ :a => 1 })
      end

      it ".foo :a => 1 setter works" do
        struct.foo :a => 1
        expect(struct.foo).to eq({ :a => 1 })
      end

      it ".foo {a:1}, true raises an error" do
        expect { struct.foo({a:1}, true) }.to raise_error(ArgumentError)
      end

      it ".foo {a:1}, {b:2}, {c:3} raises an error" do
        expect { struct.foo({a:1}, {b:2}, {c:3}) }.to raise_error(ArgumentError)
      end

      it ".foo = 10 throws an exception" do
        expect { struct.foo = 10 }.to raise_error(Moduler::ValidationFailed)
      end

      it ".foo nil yields nil" do
        expect(struct.foo nil).to be_nil
        expect(struct.is_set?(:foo)).to be_truthy
        expect(struct.foo).to be_nil
      end
    end
  end
end
