require 'support/spec_support'
require 'moduler/scope'

describe Moduler::Scope do
  context "When class Foo is a Scope" do
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

      context "And a Bar instance brings a Foo instance into scope" do
        before do
          Moduler::Scope.bring_into_scope(bar, foo)
        end

        it "Setting bar.foo_attr affects foo.foo_attr" do
          bar.foo_attr = 20
          expect(foo.foo_attr).to eq 20
        end
        it "Setting foo.foo_attr affects bar.foo_attr" do
          foo.foo_attr = 20
          expect(bar.foo_attr).to eq 20
        end
        it "Missing methods raise NoMethodError and the top of the stack is the invocation" do
          expect { bar.blarghle }.to raise_error(NoMethodError)
        end
        it "Missing variables in local eval raise NameError and the top of the stack is the invocation" do
          expect { bar.instance_eval { blarghle } }.to raise_error(NameError)
        end
      end

      context "And FooSub < Foo" do
        class FooSub < Foo
          attr_accessor :foo_sub_attr
        end
        let(:foo_sub) { FooSub.new }

        context "And a Bar instance brings a FooSub instance into scope" do
          before do
            Moduler::Scope.bring_into_scope(bar, foo_sub)
          end
          it "Setting bar.foo_attr affects foo_sub.foo_attr" do
            bar.foo_attr = 20
            expect(foo_sub.foo_attr).to eq 20
          end
          it "Setting foo_sub.foo_attr affects bar.foo_attr" do
            foo_sub.foo_attr = 20
            expect(bar.foo_attr).to eq 20
          end
          it "Setting bar.foo_sub_attr affects foo_sub.foo_sub_attr" do
            bar.foo_sub_attr = 20
            expect(foo_sub.foo_sub_attr).to eq 20
          end
          it "Setting foo_sub.foo_sub_attr affects bar.foo_sub_attr" do
            foo_sub.foo_sub_attr = 20
            expect(bar.foo_sub_attr).to eq 20
          end
        end
      end
    end
  end

  context "When Inherit3 < Inherit2 < Inherit" do
    class Inherit
      extend Moduler::Scope
      attr_accessor :inherit_attr
      def in_all
        "inherit"
      end
    end
    class Inherit2 < Inherit
      attr_accessor :inherit2_attr
      def in_all
        "inherit2"
      end
    end
    class Inherit3 < Inherit2
      attr_accessor :inherit3_attr
      def in_all
        "inherit3"
      end
    end

    context "And a Bar instance includes an Inherit3 instance" do
      let(:inherit3) { Inherit3.new }
      let(:bar) { Bar.new }
      before :each do
        Moduler::Scope.bring_into_scope(bar, inherit3)
      end
      it "in_all uses the method from Inherit3" do
        expect(inherit3.in_all).to eq "inherit3"
      end
      it "Setting bar.inherit_attr affects inherit3.inherit_attr" do
        bar.inherit_attr = 20
        expect(inherit3.inherit_attr).to eq 20
      end
      it "Setting inherit3.inherit_attr affects bar.inherit_attr" do
        inherit3.inherit_attr = 20
        expect(bar.inherit_attr).to eq 20
      end
      it "Setting bar.inherit2_attr affects inherit3.inherit2_attr" do
        bar.inherit2_attr = 20
        expect(inherit3.inherit2_attr).to eq 20
      end
      it "Setting inherit3.inherit2_attr affects bar.inherit2_attr" do
        inherit3.inherit2_attr = 20
        expect(bar.inherit2_attr).to eq 20
      end
      it "Setting bar.inherit3_attr affects inherit3.inherit3_attr" do
        bar.inherit3_attr = 20
        expect(inherit3.inherit3_attr).to eq 20
      end
      it "Setting inherit3.inherit3_attr affects bar.inherit3_attr" do
        inherit3.inherit3_attr = 20
        expect(bar.inherit3_attr).to eq 20
      end
    end
  end

  context "When Includer includes FooModule3 includes FooModule2 includes FooModule" do
    module FooModule
      extend Moduler::Scope
      def in_all
        'foo_module'
      end
      attr_accessor :foo_module_attr
    end
    module FooModule2
      include FooModule
      def in_all
        'foo_module2'
      end
      attr_accessor :foo_module2_attr
    end
    module FooModule3
      include FooModule2
      def in_all
        'foo_module3'
      end
      attr_accessor :foo_module3_attr
    end
    class Includer
      include FooModule3
    end

    context "And a Bar instance brings an Include instance into scope" do
      let(:includer) { Includer.new }
      let(:bar) { Bar.new }
      before :each do
        Moduler::Scope.bring_into_scope(bar, includer)
      end
      it "in_all uses the method from FooModule3" do
        expect(includer.in_all).to eq "foo_module3"
      end
      it "Setting bar.foo_module_attr affects includer.foo_module_attr" do
        bar.foo_module_attr = 20
        expect(includer.foo_module_attr).to eq 20
      end
      it "Setting includer.foo_module_attr affects bar.foo_module_attr" do
        includer.foo_module_attr = 20
        expect(bar.foo_module_attr).to eq 20
      end
      it "Setting bar.foo_module2_attr affects includer.foo_module2_attr" do
        bar.foo_module2_attr = 20
        expect(includer.foo_module2_attr).to eq 20
      end
      it "Setting includer.foo_module2_attr affects bar.foo_module2_attr" do
        includer.foo_module2_attr = 20
        expect(bar.foo_module2_attr).to eq 20
      end
      it "Setting bar.foo_module3_attr affects includer.foo_module3_attr" do
        bar.foo_module3_attr = 20
        expect(includer.foo_module3_attr).to eq 20
      end
      it "Setting includer.foo_module3_attr affects bar.foo_module3_attr" do
        includer.foo_module3_attr = 20
        expect(bar.foo_module3_attr).to eq 20
      end
    end

  end

  context "When Mixy < BaseClass, includes BaseModule and includes BaseModule2" do
    class BaseClass
      extend Moduler::Scope
      def in_all
        'base_class'
      end
      attr_accessor :base_class_attr
    end
    module BaseModule
      extend Moduler::Scope
      def in_all
        'base_module'
      end
      attr_accessor :base_module_attr
    end
    module BaseModule2
      extend Moduler::Scope
      def in_all
        'base_module2'
      end
      attr_accessor :base_module2_attr
    end

    class Mixy < BaseClass
      include BaseModule
      include BaseModule2
    end

    context "And a Bar instance brings a Mixy instance into scope" do
      let(:mixy) { Mixy.new }
      let(:bar) { Bar.new }
      before :each do
        Moduler::Scope.bring_into_scope(bar, mixy)
      end
      it "in_all uses the method from BaseModule2" do
        expect(mixy.in_all).to eq "base_module2"
      end
      it "Setting bar.base_class_attr affects mixy.base_class_attr" do
        bar.base_class_attr = 20
        expect(mixy.base_class_attr).to eq 20
      end
      it "Setting mixy.base_class_attr affects bar.base_class_attr" do
        mixy.base_class_attr = 20
        expect(bar.base_class_attr).to eq 20
      end
      it "Setting bar.base_module_attr affects mixy.base_module_attr" do
        bar.base_module_attr = 20
        expect(mixy.base_module_attr).to eq 20
      end
      it "Setting mixy.base_module_attr affects bar.base_module_attr" do
        mixy.base_module_attr = 20
        expect(bar.base_module_attr).to eq 20
      end
      it "Setting bar.base_module2_attr affects mixy.base_module2_attr" do
        bar.base_module2_attr = 20
        expect(mixy.base_module2_attr).to eq 20
      end
      it "Setting mixy.base_module2_attr affects bar.base_module2_attr" do
        mixy.base_module2_attr = 20
        expect(bar.base_module2_attr).to eq 20
      end
    end

  end

  context "When a class has private, protected and public methods" do
    let(:the_class) do
      Class.new do
        extend Moduler::Scope

        def to_s
          "PrivateProtectedTestClass:#{super}"
        end
        def inspect
          "PrivateProtectedTestClass:#{super}"
        end

        private
        def private1
        end

        protected
        def protected1
        end

        public
        def public1
        end
      end
    end

    let(:instance) { the_class.new }
    let(:bar) { Bar.new }
    before { Moduler::Scope.bring_into_scope(bar, instance) }

    it "Private methods do not show up" do
      expect { bar.private1 }.to raise_error(NoMethodError)
    end
    it "Protected methods do not show up" do
      expect { bar.protected1 }.to raise_error(NoMethodError)
    end
    it "Public methods do show up" do
      expect(bar.public1).to be_nil
    end

    # Other test cases:
    # undef_method
    # remove_method
    # extend Scope *after* methods added/undef/remove/protected/private/public
    # metaclass.define_method / etc.
  end
end
