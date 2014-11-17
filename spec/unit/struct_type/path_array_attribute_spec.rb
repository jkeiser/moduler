require 'support/spec_support'
require 'moduler'

module PathArrayAttributeTests
  @num = 0
end

describe Moduler do
  context "With a struct class" do
    def make_struct_class(&block)
      PathArrayAttributeTests.module_eval do
        @num += 1
        Moduler.struct("Test#{@num}") { instance_eval(&block) }
        const_get("Test#{@num}")
      end
    end

    let(:struct) do
      struct_class.new
    end

    Path = Moduler::Path

    context "with a path array attribute" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Array[Path]
        end
      end

      it "Defaults to []" do
        expect(struct.foo).to eq []
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo).to eq [Pathname.new('a/b/c')]
      end

      it ".foo = a/b/c:d/e/f sets both paths" do
        expect(struct.foo = 'a/b/c:d/e/f').to eq 'a/b/c:d/e/f'
        expect(struct.foo).to eq [Pathname.new('a/b/c'), Pathname.new('d/e/f')]
      end

      it ".foo = [a/b/c, d/e/f] sets both paths" do
        expect(struct.foo = ['a/b/c', 'd/e/f']).to eq [ 'a/b/c', 'd/e/f' ]
        expect(struct.foo).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f') ]
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq [value]
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo).to eq [Pathname.new('a/b/c')]
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq [value]
      end

      it ".foo a/b/c:d/e/f sets both" do
        struct.foo('a/b/c:d/e/f')
        expect(struct.foo).to eq [Pathname.new('a/b/c'), Pathname.new('d/e/f')]
      end

      it ".foo [a/b/c, d/e/f] sets both paths" do
        struct.foo ['a/b/c', 'd/e/f']
        expect(struct.foo).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f') ]
      end

      it ".foo a/b/c, d/e/f sets both paths" do
        struct.foo 'a/b/c', 'd/e/f'
        expect(struct.foo).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f') ]
      end

      it ".foo 'a/b/c:d/e/f', 'g/h/i:j/k/l' sets all paths" do
        struct.foo 'a/b/c:d/e/f', 'g/h/i:j/k/l'
        expect(struct.foo).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f'), Pathname.new('g/h/i'), Pathname.new('j/k/l') ]
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end
    end

    context "with a path array attribute with store_as: String" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Array[Path, store_as: String]
        end
      end

      it "Defaults to []" do
        expect(struct.foo).to eq []
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo).to eq ['a/b/c']
      end

      it ".foo = a/b/c:d/e/f sets both paths" do
        expect(struct.foo = 'a/b/c:d/e/f').to eq 'a/b/c:d/e/f'
        expect(struct.foo).to eq ['a/b/c', 'd/e/f']
      end

      it ".foo = [a/b/c, d/e/f] sets both paths" do
        expect(struct.foo = ['a/b/c', 'd/e/f']).to eq [ 'a/b/c', 'd/e/f' ]
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f' ]
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq ['a/b/c']
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo).to eq ['a/b/c']
      end

      it ".foo = a/b/c:d/e/f sets both paths" do
        struct.foo 'a/b/c:d/e/f'
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f' ]
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq ['a/b/c']
      end

      it ".foo [a/b/c, d/e/f] sets both paths" do
        struct.foo ['a/b/c', 'd/e/f']
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f' ]
      end

      it ".foo a/b/c, d/e/f sets both paths" do
        struct.foo 'a/b/c', 'd/e/f'
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f' ]
      end

      it ".foo 'a/b/c:d/e/f', 'g/h/i:j/k/l' sets all paths" do
        struct.foo 'a/b/c:d/e/f', 'g/h/i:j/k/l'
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f', 'g/h/i', 'j/k/l' ]
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end
    end

    context "with a path array attribute with store_as: String, relative_to: 'foo/bar:baz'" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Array[Path, store_as: String], relative_to: 'foo/bar:baz'
        end
      end

      it "Defaults to []" do
        expect(struct.foo).to eq []
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
      end

      it ".foo = a/b/c:d/e/f sets both paths" do
        expect(struct.foo = 'a/b/c:d/e/f').to eq 'a/b/c:d/e/f'
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo = [a/b/c, d/e/f] sets both paths" do
        expect(struct.foo = ['a/b/c', 'd/e/f']).to eq [ 'a/b/c', 'd/e/f' ]
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
      end

      it ".foo = a/b/c:d/e/f sets both paths" do
        struct.foo 'a/b/c:d/e/f'
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
      end

      it ".foo [a/b/c, d/e/f] sets both paths" do
        struct.foo ['a/b/c', 'd/e/f']
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo a/b/c, d/e/f sets both paths" do
        struct.foo 'a/b/c', 'd/e/f'
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo 'a/b/c:d/e/f', 'g/h/i:j/k/l' sets all paths" do
        struct.foo 'a/b/c:d/e/f', 'g/h/i:j/k/l'
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f', 'foo/bar/g/h/i', 'baz/g/h/i', 'foo/bar/j/k/l', 'baz/j/k/l']
      end

      it ".foo '/a/b/c:d/e/f', 'g/h/i:/j/k/l' sets all paths without relatives for absolutes" do
        struct.foo '/a/b/c:d/e/f', 'g/h/i:/j/k/l'
        expect(struct.foo).to eq ['/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f', 'foo/bar/g/h/i', 'baz/g/h/i', '/j/k/l']
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end
    end

    context "with a Windows path array attribute with relative_to: 'foo/bar;baz'" do
      let(:struct_class) do
        make_struct_class do
          attribute :foo, Array[Path::Windows], relative_to: 'foo/bar;baz'
        end
      end

      it "Defaults to []" do
        expect(struct.foo).to eq []
      end

      it ".foo = String works" do
        expect(struct.foo = 'a/b/c').to eq 'a/b/c'
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c')]
      end

      it ".foo = a/b/c;d/e/f sets both paths" do
        expect(struct.foo = 'a/b/c;d/e/f').to eq 'a/b/c;d/e/f'
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c'), Path::Windows.new('foo/bar\\d/e/f'), Path::Windows.new('baz\\d/e/f')]
      end

      it ".foo = [a/b/c, d/e/f] sets both paths" do
        expect(struct.foo = ['a/b/c', 'd/e/f']).to eq [ 'a/b/c', 'd/e/f' ]
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c'), Path::Windows.new('foo/bar\\d/e/f'), Path::Windows.new('baz\\d/e/f')]
      end

      it ".foo = Pathname works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo = value).to eq value
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c')]
      end

      it ".foo = nil works" do
        expect(struct.foo = nil).to be_nil
        expect(struct.foo).to be_nil
      end

      it ".foo String works" do
        struct.foo('a/b/c')
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c')]
      end

      it ".foo = a/b/c;d/e/f sets both paths" do
        struct.foo 'a/b/c;d/e/f'
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c'), Path::Windows.new('foo/bar\\d/e/f'), Path::Windows.new('baz\\d/e/f')]
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        struct.foo value
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c')]
      end

      it ".foo [a/b/c, d/e/f] sets both paths" do
        struct.foo ['a/b/c', 'd/e/f']
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c'), Path::Windows.new('foo/bar\\d/e/f'), Path::Windows.new('baz\\d/e/f')]
      end

      it ".foo a/b/c, d/e/f sets both paths" do
        struct.foo 'a/b/c', 'd/e/f'
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c'), Path::Windows.new('foo/bar\\d/e/f'), Path::Windows.new('baz\\d/e/f')]
      end

      it ".foo 'a/b/c;d/e/f', 'g/h/i;j/k/l' sets all paths" do
        struct.foo 'a/b/c;d/e/f', 'g/h/i;j/k/l'
        expect(struct.foo).to eq [Path::Windows.new('foo/bar\\a/b/c'), Path::Windows.new('baz\\a/b/c'), Path::Windows.new('foo/bar\\d/e/f'), Path::Windows.new('baz\\d/e/f'), Path::Windows.new('foo/bar\\g/h/i'), Path::Windows.new('baz\\g/h/i'), Path::Windows.new('foo/bar\\j/k/l'), Path::Windows.new('baz\\j/k/l')]
      end

      it ".foo '/a/b/c;d/e/f', 'g/h/i;/j/k/l' sets all paths without relatives for absolutes" do
        struct.foo '/a/b/c;d/e/f', 'g/h/i;/j/k/l'
        expect(struct.foo).to eq [Path::Windows.new('/a/b/c'), Path::Windows.new('foo/bar\\d/e/f'), Path::Windows.new('baz\\d/e/f'), Path::Windows.new('foo/bar\\g/h/i'), Path::Windows.new('baz\\g/h/i'), Path::Windows.new('/j/k/l')]
      end

      it ".foo nil works" do
        struct.foo nil
        expect(struct.foo).to be_nil
      end
    end

  end
end
