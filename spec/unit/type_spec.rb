require 'support/spec_support'
require 'moduler/type'
require 'moduler/type/coercer'
require 'moduler/type/coercer_out'
require 'moduler/lazy_value'

describe Moduler::Type do
  let(:type) { Moduler::Type.new }
  NO_VALUE = Moduler::NO_VALUE

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
    it "By default, coerce returns the input value" do
      expect(type.coerce(100)).to eq 100
      expect(type.coerce(nil)).to be_nil
    end

    it "When a coercer is specified, it is called" do
      type.coercers << MultiplyCoercer.new(2)
      expect(type.coerce(100)).to eq 200
    end

    it "When multiple coercers are specified, their values stack" do
      type.coercers << MultiplyCoercer.new(2)
      type.coercers << MultiplyCoercer.new(3)
      expect(type.coerce(100)).to eq 600
    end

    it "When given a lazy value, coercers are not run and the value is returned" do
      type.coercers << MultiplyCoercer.new(2)
      lazy = Moduler::LazyValue.new { 100 }
      expect(type.coerce(lazy)).to eq lazy
    end

    it "When given a non-caching lazy value, coercers are not run and the value is returned" do
      type.coercers << MultiplyCoercer.new(2)
      lazy = Moduler::LazyValue.new(false) { 100 }
      expect(type.coerce(lazy)).to eq lazy
    end
  end

  describe "coerce_out" do
    it "By default, coerce_out returns the input value" do
      expect(type.coerce_out(100)).to eq 100
      expect(type.coerce_out(nil)).to be_nil
    end

    it "When a coerce_out is specified, it is called" do
      type.coercers_out << MultiplyCoercerOut.new(2)
      expect(type.coerce_out(100)).to eq 200
    end

    it "When multiple coerce_outs are specified, their values stack" do
      type.coercers_out << MultiplyCoercerOut.new(2)
      type.coercers_out << MultiplyCoercerOut.new(3)
      expect(type.coerce_out(100)).to eq 600
    end

    context "default values" do
      it "When NO_VALUE is passed, and no default_value is specified, NO_VALUE is returned" do
        expect(type.coerce_out(NO_VALUE)).to eq NO_VALUE
      end

      it "When NO_VALUE is passed, and a default_value is specified, it is returned" do
        type.default_value = 100
        expect(type.coerce_out(NO_VALUE)).to eq 100
      end

      it "When NO_VALUE is passed, and a default_value is specified, coercers_out are run but coercers are not" do
        type.default_value = 100
        type.coercers << MultiplyCoercer.new(2)
        type.coercers_out << MultiplyCoercerOut.new(3)
        expect(type.coerce_out(NO_VALUE)).to eq 300
      end

      it "When NO_VALUE is passed, and a lazy default_value is specified, it is returned" do
        type.default_value = Moduler::LazyValue.new { 100 }
        expect(type.coerce_out(NO_VALUE)).to eq 100
      end

      it "When NO_VALUE is passed, and a lazy default_value is specified, it is cached and returned" do
        cache = 0
        run = 0
        type.default_value = Moduler::LazyValue.new { run += 1; 100 }
        type.coercers << MultiplyCoercer.new(2)
        type.coercers_out << MultiplyCoercerOut.new(3)

        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 300
        expect(cache).to eq 100
        expect(type.coerce_out(cache)).to eq 300
        expect(cache).to eq 100
        expect(run).to eq 1
      end

      it "When NO_VALUE is passed, and a non-caching lazy default_value is specified, it is cached and returned" do
        cache = 0
        run = 0
        type.default_value = Moduler::LazyValue.new(false) { run += 1; 100 }
        type.coercers << MultiplyCoercer.new(2)
        type.coercers_out << MultiplyCoercerOut.new(3)

        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 300
        expect(cache).to eq 0
        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 300
        expect(cache).to eq 0
        expect(run).to eq 2
      end

      it "When NO_VALUE is passed, and a lazy default_value is specified, and no cache_proc is specified, the coerced value is returned" do
        cache = 0
        run = 0
        type.default_value = Moduler::LazyValue.new { run += 1; 100 }
        type.coercers << MultiplyCoercer.new(2)
        type.coercers_out << MultiplyCoercerOut.new(3)

        expect(type.coerce_out(NO_VALUE)).to eq 300
        expect(cache).to eq 0
        expect(type.coerce_out(NO_VALUE)).to eq 300
        expect(cache).to eq 0
        expect(run).to eq 2
      end
    end

    context "Lazy value" do

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
        type.coercers << MultiplyCoercer.new(2)
        type.coercers << MultiplyCoercer.new(3)
        type.coercers_out << MultiplyCoercerOut.new(5)
        type.coercers_out << MultiplyCoercerOut.new(7)
        cache = 0
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 }) { |v| cache=v }).to eq 21000
        expect(cache).to eq 600
        expect(type.coerce_out(cache) { |v| cache=v }).to eq 21000
        expect(cache).to eq 600
        expect(run).to eq 1
      end

      it "When given a lazy value and no cache_proc, both coercers and out coercers are run" do
        type.coercers << MultiplyCoercer.new(2)
        type.coercers << MultiplyCoercer.new(3)
        type.coercers_out << MultiplyCoercerOut.new(5)
        type.coercers_out << MultiplyCoercerOut.new(7)
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 21000
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 21000
        expect(run).to eq 2
      end

      it "When given a non-caching lazy value, both coercers and out coercers are run and nothing is cached" do
        type.coercers << MultiplyCoercer.new(2)
        type.coercers << MultiplyCoercer.new(3)
        type.coercers_out << MultiplyCoercerOut.new(5)
        type.coercers_out << MultiplyCoercerOut.new(7)
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
      end.new
    end
    context "default_call" do
      context "When value is NO_VALUE" do
        before { value.set(NO_VALUE) }

        it "type.call() is called with no arguments" do
          expect(type.call(value)).to eq NO_VALUE
        end

        it "type.call() does not run coercers_out or coercers" do
          type.coercers << MultiplyCoercer.new(2)
          type.coercers_out << MultiplyCoercerOut.new(3)
          expect(type.call(value)).to eq NO_VALUE
        end

        it "type.call() with default_value returns the default value" do
          type.default_value = 100
          expect(type.call(value)).to eq 100
        end

        it "type.call() with default_value runs coercers_out but not coercers" do
          type.default_value = 100
          type.coercers << MultiplyCoercer.new(2)
          type.coercers_out << MultiplyCoercerOut.new(3)
          expect(type.call(value)).to eq 300
        end

        it "type.call() with lazy default_value caches and returns the default value" do
          type.default_value = Moduler::LazyValue.new { 100 }
          expect(type.call(value)).to eq 100
          expect(value.get).to eq 100
        end

        it "type.call() with lazy default_value caches the default value and returns the coerced default value" do
          type.default_value = Moduler::LazyValue.new { 100 }
          type.coercers << MultiplyCoercer.new(2)
          type.coercers_out << MultiplyCoercerOut.new(3)
          expect(type.call(value)).to eq 300
          expect(value.get).to eq 100
        end

        it "type.call() with lazy default_value and no cache returns the default value and does not cache" do
          type.default_value = Moduler::LazyValue.new(false) { 100 }
          expect(type.call(value)).to eq 100
          expect(value.get).to eq NO_VALUE
        end
      end

      it "type.call(value) sets the value" do
        expect(type.call(value, 100)).to eq 100
        expect(value.get).to eq 100
      end

      it "type.call(value) runs coercers and returns a value with coercers_out" do
        type.coercers << MultiplyCoercer.new(2)
        type.coercers_out << MultiplyCoercerOut.new(3)
        expect(type.call(value, 100)).to eq 600
        expect(value.get).to eq 200
      end

      it "type.call(&block) sets the value to the block" do
        block = proc { 100 }
        expect(type.call(value, &block)).to eq block
        expect(value.get).to eq block
      end

      it "type.call(&block) with coercers and coercers_out sets the value to the block" do
        block = proc { 100 }
        type.coercers << WrapMultiplyCoercer.new(2)
        type.coercers_out << WrapMultiplyCoercerOut.new(3)
        expect(type.call(value, &block).call).to eq 600
        expect(value.get.call).to eq 200
      end
    end
  end
  describe "on_set" do
    it "When on_set listeners are added, the event fires to them" do
      blah = []
      type.register(:on_set) { |x, &block| blah << x*block.call }
      type.register(:on_set) { |x, &block| blah << x+block.call }
      type.events[:on_set].fire(2) { 3 }
      expect(blah).to eq [ 6, 5 ]
    end
  end
end
