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

    Path = Moduler::Path

    context "with a path attribute" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path
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
        struct.foo('a/b/c')
        expect(struct.foo.to_s).to eq 'a/b/c'
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq value
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo.to_s).to eq 'a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo.to_s).to eq 'a/b/c/d'
      end
    end

    context "with a path attribute with store_as: Path::Unix" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path::Unix
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
        struct.foo('a/b/c')
        expect(struct.foo.to_s).to eq 'a/b/c'
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq value
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo.to_s).to eq 'a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo.to_s).to eq 'a/b/c/d'
      end
    end

    context "with a path attribute with store_as: Path::Windows" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path::Windows
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
        struct.foo('a/b/c')
        expect(struct.foo.to_s).to eq 'a/b/c'
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq value
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a\\b\\c\\d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo.to_s).to eq 'a\\b\\c\\d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo.to_s).to eq 'a/b/c/d'
      end
    end

    context "with a path attribute with store_as: String" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path, store_as: String
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
        struct.foo('a/b/c')
        expect(struct.foo).to eq 'a/b/c'
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq 'a/b/c'
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo).to eq 'a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo).to eq 'a/b/c/d'
      end
    end

    let(:path_sep) { File::ALT_SEPARATOR || File::SEPARATOR }
    context "with a path attribute with relative_to: 'foo/bar'" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path, relative_to: 'foo/bar'
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
        expect(struct.foo).to eq Path.new("foo/bar#{path_sep}a/b/c")
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo.to_s).to eq "foo/bar#{path_sep}a/b/c"
      end

      it ".foo /a/b/c does not add relative" do
        struct.foo('/a/b/c')
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq Path.new("foo/bar#{path_sep}a/b/c")
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end
    end

    context "with a path attribute with relative_to: Pathname.new('foo/bar')" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path, relative_to: Pathname.new('foo/bar')
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
        expect(struct.foo).to eq Path.new('foo/bar/a/b/c')
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c'
      end

      it ".foo /a/b/c does not add relative" do
        struct.foo('/a/b/c')
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq Path.new('foo/bar/a/b/c')
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo.to_s).to eq 'foo/bar/a/b/c/d'
      end
    end

    context "with a Windows path attribute with relative_to: 'foo/bar'" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path::Windows, relative_to: 'foo/bar'
        end
      end

      it "Defaults to nil" do
        expect(struct.foo).to be_nil
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo.to_s).to eq "foo/bar\\a/b/c"
      end

      it ".foo = /a/b/c does not add relative" do
        expect(struct.foo = '/a/b/c').to eq '/a/b/c'
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq Path.new("foo/bar\\a/b/c")
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo.to_s).to eq "foo/bar\\a/b/c"
      end

      it ".foo /a/b/c does not add relative" do
        struct.foo('/a/b/c')
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq Path.new("foo/bar\\a/b/c")
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to foo/bar\\a\\b\\c\\d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo.to_s).to eq 'foo/bar\\a\\b\\c\\d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to foo/bar\\a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo.to_s).to eq 'foo/bar\\a/b/c/d'
      end
    end

    context "with a Windows path attribute with relative_to: Pathname.new('foo/bar')" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Path::Windows, relative_to: Pathname.new('foo/bar')
        end
      end

      it "Defaults to nil" do
        expect(struct.foo).to be_nil
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo.to_s).to eq 'foo/bar\\a/b/c'
      end

      it ".foo /a/b/c does not add relative" do
        expect(struct.foo = '/a/b/c').to eq '/a/b/c'
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq Path.new('foo/bar\\a/b/c')
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo.to_s).to eq 'foo/bar\\a/b/c'
      end

      it ".foo /a/b/c does not add relative" do
        struct.foo('/a/b/c')
        expect(struct.foo.to_s).to eq "/a/b/c"
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq Path.new('foo/bar\\a/b/c')
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end

      it ".foo %w(a b c d) sets to a/b/c/d" do
        struct.foo(*%w(a b c d))
        expect(struct.foo.to_s).to eq 'foo/bar\\a\\b\\c\\d'
      end

      it ".foo Pathname.new('a'), %w(b c d) sets to a/b/c/d" do
        struct.foo(Pathname.new('a'), *%w(b c d))
        expect(struct.foo.to_s).to eq 'foo/bar\\a/b/c/d'
      end
    end
  end
end
