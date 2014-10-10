require 'support/spec_support'
require 'moduler/type'
require 'moduler/type/coercer'
require 'moduler/type/coercer_out'
require 'moduler/lazy_value'
require 'moduler/type/coercer/compound_coercer'
require 'moduler/type/coercer_out/compound_coercer_out'

describe Moduler::Type do
  let(:type) do
    type = Moduler::Type.new
    type.register(:on_set) do |v|
      expect(v.type).to eq type
      on_set << v.value
    end
    type
  end
  NO_VALUE = Moduler::NO_VALUE
  def on_set
    @on_set ||= []
  end

  class MultiplyCoercer
    extend Moduler::Type::Coercer
    def initialize(n)
      @n = n
    end
    def coerce(value)
      value*@n
    end
  end
  class MultiplyCoercerOut
    extend Moduler::Type::CoercerOut
    def initialize(n)
      @n = n
    end
    def coerce_out(value)
      value*@n
    end
  end

  class WrapMultiplyCoercer
    extend Moduler::Type::Coercer
    def initialize(n)
      @n = n
    end
    def coerce(value)
      proc { value.call*@n }
    end
  end
  class WrapMultiplyCoercerOut
    extend Moduler::Type::CoercerOut
    def initialize(n)
      @n = n
    end
    def coerce_out(value)
      proc { value.call*@n }
    end
  end

  describe "coerce" do
    after { expect(on_set).to eq [] }

    it "By default, coerce returns the input value" do
      expect(type.coerce(100)).to eq 100
      expect(type.coerce(nil)).to be_nil
    end

    it "When a coercer is specified, it is called" do
      type.coercer = MultiplyCoercer.new(2)
      expect(type.coerce(100)).to eq 200
    end

    it "When multiple coercers are specified, their values stack" do
      type.coercer = Moduler::Type::Coercer::CompoundCoercer.new(
        MultiplyCoercer.new(2),
        MultiplyCoercer.new(3)
      )
      expect(type.coerce(100)).to eq 600
    end

    it "When given a lazy value, coercers are not run and the value is returned" do
      type.coercer = MultiplyCoercer.new(2)
      lazy = Moduler::LazyValue.new { 100 }
      expect(type.coerce(lazy)).to eq lazy
    end

    it "When given a non-caching lazy value, coercers are not run and the value is returned" do
      type.coercer = MultiplyCoercer.new(2)
      lazy = Moduler::LazyValue.new(false) { 100 }
      expect(type.coerce(lazy)).to eq lazy
    end
  end

  describe "coerce_out" do
    after { expect(on_set).to eq [] }

    it "By default, coerce_out returns the input value" do
      expect(type.coerce_out(100)).to eq 100
      expect(type.coerce_out(nil)).to be_nil
    end

    it "When a coerce_out is specified, it is called" do
      type.coercer_out = MultiplyCoercerOut.new(2)
      expect(type.coerce_out(100)).to eq 200
    end

    it "When multiple coerce_outs are specified, their values stack" do
      type.coercer_out = Moduler::Type::CoercerOut::CompoundCoercerOut.new(
        MultiplyCoercerOut.new(2),
        MultiplyCoercerOut.new(3)
      )
      expect(type.coerce_out(100)).to eq 600
    end

    context "default values" do
      after { expect(on_set).to eq [] }

      it "When NO_VALUE is passed, and no default is specified, NO_VALUE is returned" do
        expect(type.coerce_out(NO_VALUE)).to eq NO_VALUE
      end

      it "When NO_VALUE is passed, and a default is specified, it is returned" do
        type.default = 100
        expect(type.coerce_out(NO_VALUE)).to eq 100
      end

      it "When NO_VALUE is passed, and a default is specified, coercers_out are run but coercers are not" do
        type.coercer = MultiplyCoercer.new(2)
        type.coercer_out = MultiplyCoercerOut.new(3)
        type.default = 100
        expect(type.coerce_out(NO_VALUE)).to eq 600
      end

      it "When NO_VALUE is passed, and a lazy default is specified, it is returned" do
        type.default = Moduler::LazyValue.new { 100 }
        expect(type.coerce_out(NO_VALUE)).to eq 100
      end

      it "When NO_VALUE is passed, and a lazy default is specified, it is cached and returned" do
        cache = 0
        run = 0
        type.default = Moduler::LazyValue.new { run += 1; 100 }
        type.coercer = MultiplyCoercer.new(2)
        type.coercer_out = MultiplyCoercerOut.new(3)

        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 600
        expect(cache).to eq 200
        expect(type.coerce_out(cache)).to eq 600
        expect(cache).to eq 200
        expect(run).to eq 1
      end

      it "When NO_VALUE is passed, and a non-caching lazy default is specified, it is cached and returned" do
        cache = 0
        run = 0
        type.default = Moduler::LazyValue.new(false) { run += 1; 100 }
        type.coercer = MultiplyCoercer.new(2)
        type.coercer_out = MultiplyCoercerOut.new(3)

        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 600
        expect(cache).to eq 0
        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 600
        expect(cache).to eq 0
        expect(run).to eq 2
      end

      it "When NO_VALUE is passed, and a lazy default is specified, and no cache_proc is specified, the coerced value is returned" do
        cache = 0
        run = 0
        type.default = Moduler::LazyValue.new { run += 1; 100 }
        type.coercer = MultiplyCoercer.new(2)
        type.coercer_out = MultiplyCoercerOut.new(3)

        expect(type.coerce_out(NO_VALUE)).to eq 600
        expect(cache).to eq 0
        expect(type.coerce_out(NO_VALUE)).to eq 600
        expect(cache).to eq 0
        expect(run).to eq 2
      end
    end

    context "Lazy value" do
      after { expect(on_set).to eq [] }

      it "When given a lazy value, by default, the value is returned and cached" do
        cache = 0
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 }) { |v| cache=v }).to eq 100
        expect(cache).to eq 100
        expect(type.coerce_out(cache) { |v| cache=v }).to eq 100
        expect(cache).to eq 100
        expect(run).to eq 1
      end

      it "When given a lazy value and no cache_proc, the value is returned" do
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 100
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 100
        expect(run).to eq 2
      end

      it "When given a non-caching lazy value, the value is returned and not cached" do
        cache = 0
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new(false) { run += 1; 100 }) { |v| cache=v }).to eq 100
        expect(cache).to eq 0
        expect(type.coerce_out(Moduler::LazyValue.new(false) { run += 1; 100 }) { |v| cache=v }).to eq 100
        expect(cache).to eq 0
        expect(run).to eq 2
      end

      it "When given a lazy value, both coercers and out coercers are run and the intermediate value is cached" do
        type.coercer = Moduler::Type::Coercer::CompoundCoercer.new(
          MultiplyCoercer.new(2),
          MultiplyCoercer.new(3)
        )
        type.coercer_out = Moduler::Type::CoercerOut::CompoundCoercerOut.new(
          MultiplyCoercerOut.new(5),
          MultiplyCoercerOut.new(7)
        )
        cache = 0
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 }) { |v| cache=v }).to eq 21000
        expect(cache).to eq 600
        expect(type.coerce_out(cache) { |v| cache=v }).to eq 21000
        expect(cache).to eq 600
        expect(run).to eq 1
      end

      it "When given a lazy value and no cache_proc, both coercers and out coercers are run" do
        type.coercer = Moduler::Type::Coercer::CompoundCoercer.new(
          MultiplyCoercer.new(2),
          MultiplyCoercer.new(3)
        )
        type.coercer_out = Moduler::Type::CoercerOut::CompoundCoercerOut.new(
          MultiplyCoercerOut.new(5),
          MultiplyCoercerOut.new(7)
        )
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 21000
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 21000
        expect(run).to eq 2
      end

      it "When given a non-caching lazy value, both coercers and out coercers are run and nothing is cached" do
        type.coercer = Moduler::Type::Coercer::CompoundCoercer.new(
          MultiplyCoercer.new(2),
          MultiplyCoercer.new(3)
        )
        type.coercer_out = Moduler::Type::CoercerOut::CompoundCoercerOut.new(
          MultiplyCoercerOut.new(5),
          MultiplyCoercerOut.new(7)
        )
        cache = 0
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new(false) { run += 1; 100 }) { |v| cache=v }).to eq 21000
        expect(cache).to eq 0
        expect(type.coerce_out(Moduler::LazyValue.new(false) { run += 1; 100 }) { |v| cache=v }).to eq 21000
        expect(cache).to eq 0
        expect(run).to eq 2
      end
    end
  end
  describe "call" do
    let(:value) do
      Class.new do
        def get
          @value
        end
        def set(value)
          @value = value
        end
        def to_s
          "CallValue #{super}"
        end
      end.new
    end
    context "default_call" do
      context "When value is NO_VALUE" do
        before { value.set(NO_VALUE) }
        after { expect(on_set).to eq [] }

        it "type.call() is called with no arguments" do
          expect(type.call(value)).to eq NO_VALUE
        end

        it "type.call() does not run coercers_out or coercers" do
          type.coercer = MultiplyCoercer.new(2)
          type.coercer_out = MultiplyCoercerOut.new(3)
          expect(type.call(value)).to eq NO_VALUE
        end

        it "type.call() with default returns the default value" do
          type.default = 100
          expect(type.call(value)).to eq 100
        end

        it "type.call() with default runs coercers_out but not coercers" do
          type.coercer = MultiplyCoercer.new(2)
          type.coercer_out = MultiplyCoercerOut.new(3)
          type.default = 100
          expect(type.call(value)).to eq 600
        end

        it "type.call() with lazy default caches and returns the default value" do
          type.default = Moduler::LazyValue.new { 100 }
          expect(type.call(value)).to eq 100
          expect(value.get).to eq 100
        end

        it "type.call() with lazy default caches the default value and returns the coerced default value" do
          type.default = Moduler::LazyValue.new { 100 }
          type.coercer = MultiplyCoercer.new(2)
          type.coercer_out = MultiplyCoercerOut.new(3)
          expect(type.call(value)).to eq 600
          expect(value.get).to eq 200
        end

        it "type.call() with lazy default and no cache returns the default value and does not cache" do
          type.default = Moduler::LazyValue.new(false) { 100 }
          expect(type.call(value)).to eq 100
          expect(value.get).to eq NO_VALUE
        end
      end

      it "type.call(value) sets the value" do
        expect(type.call(value, 100)).to eq 100
        expect(value.get).to eq 100
        expect(on_set).to eq [ 100 ]
      end

      it "type.call(value) runs coercers and returns a value with coercers_out" do
        type.coercer = MultiplyCoercer.new(2)
        type.coercer_out = MultiplyCoercerOut.new(3)
        expect(type.call(value, 100)).to eq 600
        expect(value.get).to eq 200
        expect(on_set).to eq [ 600 ]
      end

      it "type.call(&block) sets the value to the block" do
        block = proc { 100 }
        expect(type.call(value, &block)).to eq block
        expect(value.get).to eq block
        expect(on_set).to eq [ block ]
      end

      it "type.call(&block) with coercers and coercers_out sets the value to the block" do
        block = proc { 100 }
        type.coercer = WrapMultiplyCoercer.new(2)
        type.coercer_out = WrapMultiplyCoercerOut.new(3)
        expect(type.call(value, &block).call).to eq 600
        expect(value.get.call).to eq 200
        expect(on_set.map { |x| x.call }).to eq [ 600 ]
      end
    end
  end
end
