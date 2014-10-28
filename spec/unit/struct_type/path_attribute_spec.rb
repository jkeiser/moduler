require 'support/spec_support'
require 'moduler'

module PathAttributeTests
  @num = 0
end

describe Moduler do
  context "With a struct class" do
    def make_struct_class(&block)
      PathAttributeTests.module_eval do
        @num += 1
        Moduler.struct("Test#{@num}") { instance_eval(&block) }
        const_get("Test#{@num}")
      end
    end

    let(:struct) do
      struct_class.new
    end

    context "with a path attribute" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Moduler::Path
        end
      end

      it "Defaults to nil" do
        expect(struct.foo).to be_nil
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo.to_s).to eq 'a/b/c'
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq value
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        expect(struct.foo('a/b/c').to_s).to eq 'a/b/c'
        expect(struct.foo.to_s).to eq 'a/b/c'
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo value).to eq value
        expect(struct.foo).to eq value
      end

      it ".foo nil works" do
        expect(struct.foo nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        expect(struct.foo(*%w(a b c d)).to_s).to eq 'a/b/c/d'
        expect(struct.foo.to_s).to eq 'a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        expect(struct.foo(Pathname.new('a'), *%w(b c d)).to_s).to eq 'a/b/c/d'
        expect(struct.foo.to_s).to eq 'a/b/c/d'
      end
    end

    context "with a path attribute with store_as: String" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Moduler::Path, store_as: String
        end
      end

      it "Defaults to nil" do
        expect(struct.foo).to be_nil
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo).to eq 'a/b/c'
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq 'a/b/c'
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        expect(struct.foo('a/b/c')).to eq 'a/b/c'
        expect(struct.foo).to eq 'a/b/c'
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo value).to eq 'a/b/c'
        expect(struct.foo).to eq 'a/b/c'
      end

      it ".foo nil works" do
        expect(struct.foo nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        expect(struct.foo(*%w(a b c d))).to eq 'a/b/c/d'
        expect(struct.foo).to eq 'a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        expect(struct.foo(Pathname.new('a'), *%w(b c d))).to eq 'a/b/c/d'
        expect(struct.foo).to eq 'a/b/c/d'
      end
    end

    let(:path_sep) { File::ALT_SEPARATOR || File::SEPARATOR }
    context "with a path attribute with relative_to: 'foo/bar'" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Moduler::Path, relative_to: 'foo/bar'
        end
      end

      it "Defaults to nil" do
        expect(struct.foo).to be_nil
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo.to_s).to eq "foo/bar#{path_sep}a/b/c"
      end

      it ".foo = /a/b/c does not add relative" do
        expect(struct.foo = '/a/b/c').to eq '/a/b/c'
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq Moduler::Path.new("foo/bar#{path_sep}a/b/c")
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        expect(struct.foo('a/b/c').to_s).to eq "foo/bar#{path_sep}a/b/c"
        expect(struct.foo.to_s).to eq "foo/bar#{path_sep}a/b/c"
      end

      it ".foo /a/b/c does not add relative" do
        expect(struct.foo('/a/b/c').to_s).to eq '/a/b/c'
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo value).to eq Moduler::Path.new("foo/bar#{path_sep}a/b/c")
        expect(struct.foo).to eq Moduler::Path.new("foo/bar#{path_sep}a/b/c")
      end

      it ".foo nil works" do
        expect(struct.foo nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        expect(struct.foo(*%w(a b c d)).to_s).to eq 'foo/bar/a/b/c/d'
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        expect(struct.foo(Pathname.new('a'), *%w(b c d)).to_s).to eq 'foo/bar/a/b/c/d'
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end
    end

    context "with a path attribute with relative_to: Pathname.new('foo/bar')" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Moduler::Path, relative_to: Pathname.new('foo/bar')
        end
      end

      it "Defaults to nil" do
        expect(struct.foo).to be_nil
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c'
      end

      it ".foo /a/b/c does not add relative" do
        expect(struct.foo = '/a/b/c').to eq '/a/b/c'
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq Moduler::Path.new('foo/bar/a/b/c')
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        expect(struct.foo('a/b/c').to_s).to eq 'foo/bar/a/b/c'
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c'
      end

      it ".foo /a/b/c does not add relative" do
        expect(struct.foo('/a/b/c').to_s).to eq '/a/b/c'
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo value).to eq Moduler::Path.new('foo/bar/a/b/c')
        expect(struct.foo).to eq Moduler::Path.new('foo/bar/a/b/c')
      end

      it ".foo nil works" do
        expect(struct.foo nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        expect(struct.foo(*%w(a b c d)).to_s).to eq 'foo/bar/a/b/c/d'
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        expect(struct.foo(Pathname.new('a'), *%w(b c d)).to_s).to eq 'foo/bar/a/b/c/d'
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end
    end

  end
end
