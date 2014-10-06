require 'support/spec_support'
require 'moduler/scope'

describe Moduler::Scope do
  context "When class Foo includes Scope" do
    class Foo
      extend Moduler::Scope
      attr_accessor :foo_attr
    end

    let (:foo) { Foo.new }

    context "And Bar does *not* extend Foo" do
      class Bar
        attr_accessor :bar_attr
      end
      let (:bar) { Bar.new }

      context "And a Bar instance extends a Foo instance" do
        before do
          Moduler::Scope.extend_instance(bar, foo)
        end

        it "Setting bar.foo_attr affects foo.foo_attr" do
          bar.foo_attr = 20
          expect(foo.foo_attr).to eq 20
        end
        it "Setting foo.foo_attr affects bar.foo_attr" do
          foo.foo_attr = 20
          expect(bar.foo_attr).to eq 20
        end
      end
    end

    context "And Bar has Foo as its container class (but does not extend it)" do
      class BarWithContainer
        Moduler::Scope.set_container_class(self, Foo)
        def initialize(foo)
          Moduler::Scope.set_container(self, foo)
        end
        attr_accessor :bar_attr
      end

      context "And a Bar instance has a Foo instance as its container" do
        let (:bar) { BarWithContainer.new(foo) }

        it "Setting bar.foo_attr affects foo.foo_attr" do
          bar.foo_attr = 20
          expect(foo.foo_attr).to eq 20
        end
        it "Setting foo.foo_attr affects bar.foo_attr" do
          foo.foo_attr = 20
          expect(bar.foo_attr).to eq 20
        end
      end
    end
  end
end
