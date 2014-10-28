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
        expect(struct.foo('a/b/c')).to eq [Pathname.new('a/b/c')]
        expect(struct.foo).to eq [Pathname.new('a/b/c')]
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo value).to eq [value]
        expect(struct.foo).to eq [value]
      end

      it ".foo a/b/c:d/e/f sets both" do
        expect(struct.foo('a/b/c:d/e/f')).to eq [Pathname.new('a/b/c'), Pathname.new('d/e/f')]
        expect(struct.foo).to eq [Pathname.new('a/b/c'), Pathname.new('d/e/f')]
      end

      it ".foo [a/b/c, d/e/f] sets both paths" do
        expect(struct.foo ['a/b/c', 'd/e/f']).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f') ]
        expect(struct.foo).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f') ]
      end

      it ".foo a/b/c, d/e/f sets both paths" do
        expect(struct.foo 'a/b/c', 'd/e/f').to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f') ]
        expect(struct.foo).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f') ]
      end

      it ".foo 'a/b/c:d/e/f', 'g/h/i:j/k/l' sets all paths" do
        expect(struct.foo 'a/b/c:d/e/f', 'g/h/i:j/k/l').to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f'), Pathname.new('g/h/i'), Pathname.new('j/k/l') ]
        expect(struct.foo).to eq [ Pathname.new('a/b/c'), Pathname.new('d/e/f'), Pathname.new('g/h/i'), Pathname.new('j/k/l') ]
      end

      it ".foo nil works" do
        expect(struct.foo nil).to be_nil
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
        expect(struct.foo('a/b/c')).to eq ['a/b/c']
        expect(struct.foo).to eq ['a/b/c']
      end

      it ".foo = a/b/c:d/e/f sets both paths" do
        expect(struct.foo 'a/b/c:d/e/f').to eq [ 'a/b/c', 'd/e/f' ]
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f' ]
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo value).to eq ['a/b/c']
        expect(struct.foo).to eq ['a/b/c']
      end

      it ".foo [a/b/c, d/e/f] sets both paths" do
        expect(struct.foo ['a/b/c', 'd/e/f']).to eq [ 'a/b/c', 'd/e/f' ]
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f' ]
      end

      it ".foo a/b/c, d/e/f sets both paths" do
        expect(struct.foo 'a/b/c', 'd/e/f').to eq [ 'a/b/c', 'd/e/f' ]
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f' ]
      end

      it ".foo 'a/b/c:d/e/f', 'g/h/i:j/k/l' sets all paths" do
        expect(struct.foo 'a/b/c:d/e/f', 'g/h/i:j/k/l').to eq [ 'a/b/c', 'd/e/f', 'g/h/i', 'j/k/l' ]
        expect(struct.foo).to eq [ 'a/b/c', 'd/e/f', 'g/h/i', 'j/k/l' ]
      end

      it ".foo nil works" do
        expect(struct.foo nil).to be_nil
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
        expect(struct.foo('a/b/c')).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
      end

      it ".foo = a/b/c:d/e/f sets both paths" do
        expect(struct.foo 'a/b/c:d/e/f').to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo(Pathname) works" do
        value = Pathname.new('a/b/c')
        expect(struct.foo value).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c']
      end

      it ".foo [a/b/c, d/e/f] sets both paths" do
        expect(struct.foo ['a/b/c', 'd/e/f']).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo a/b/c, d/e/f sets both paths" do
        expect(struct.foo 'a/b/c', 'd/e/f').to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f']
      end

      it ".foo 'a/b/c:d/e/f', 'g/h/i:j/k/l' sets all paths" do
        expect(struct.foo 'a/b/c:d/e/f', 'g/h/i:j/k/l').to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f', 'foo/bar/g/h/i', 'baz/g/h/i', 'foo/bar/j/k/l', 'baz/j/k/l']
        expect(struct.foo).to eq ['foo/bar/a/b/c', 'baz/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f', 'foo/bar/g/h/i', 'baz/g/h/i', 'foo/bar/j/k/l', 'baz/j/k/l']
      end

      it ".foo '/a/b/c:d/e/f', 'g/h/i:/j/k/l' sets all paths without relatives for absolutes" do
        expect(struct.foo '/a/b/c:d/e/f', 'g/h/i:/j/k/l').to eq ['/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f', 'foo/bar/g/h/i', 'baz/g/h/i', '/j/k/l']
        expect(struct.foo).to eq ['/a/b/c', 'foo/bar/d/e/f', 'baz/d/e/f', 'foo/bar/g/h/i', 'baz/g/h/i', '/j/k/l']
      end

      it ".foo nil works" do
        expect(struct.foo nil).to be_nil
        expect(struct.foo).to be_nil
      end
    end
  end
end
