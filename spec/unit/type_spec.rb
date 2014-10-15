require 'support/spec_support'
require 'moduler/type'
require 'moduler/lazy_value'

describe Moduler::Type do
  let(:type) do
    Moduler::Type.new
  end
  NO_VALUE = Moduler::NO_VALUE

  describe "coerce" do
    #after { expect(on_set).to eq [] }

    it "By default, coerce returns the input value" do
      expect(type.coerce(100)).to eq 100
      expect(type.coerce(nil)).to be_nil
    end

    it "When a coercer is specified, it is called" do
      type = MultiplyCoercer.new in_val: 2
      expect(type.coerce(100)).to eq 200
    end

    it "When given a lazy value, coercers are not run and the value is returned" do
      type = MultiplyCoercer.new in_val: 2
      lazy = Moduler::LazyValue.new { 100 }
      expect(type.coerce(lazy)).to eq lazy
    end

    it "When given a non-caching lazy value, coercers are not run and the value is returned" do
      type = MultiplyCoercer.new in_val: 2
      lazy = Moduler::LazyValue.new(false) { 100 }
      expect(type.coerce(lazy)).to eq lazy
    end
  end

  describe "coerce_out" do
    #after { expect(on_set).to eq [] }

    it "By default, coerce_out returns the input value" do
      expect(type.coerce_out(100)).to eq 100
      expect(type.coerce_out(nil)).to be_nil
    end

    it "When a coerce_out is specified, it is called" do
      type = MultiplyCoercer.new out_val: 2
      expect(type.coerce_out(100)).to eq 200
    end

    context "default values" do
      #after { expect(on_set).to eq [] }

      it "When NO_VALUE is passed, and no default is specified, nil is returned" do
        expect(type.coerce_out(NO_VALUE)).to eq nil
      end

      it "When NO_VALUE is passed, and a default is specified, it is returned" do
        type.default = 100
        expect(type.coerce_out(NO_VALUE)).to eq 100
      end

      it "When NO_VALUE is passed, and a default is specified, coercers are run" do
        type = MultiplyCoercer.new in_val: 2, out_val: 3
        type.default = 100
        expect(type.default).to eq 600
        expect(type.coerce_out(NO_VALUE)).to eq 600
      end

      it "When NO_VALUE is passed, and a lazy default is specified, it is returned" do
        type.default = Moduler::LazyValue.new { 100 }
        expect(type.coerce_out(NO_VALUE)).to eq 100
      end

      it "When NO_VALUE is passed, and a lazy default is specified, it is cached and returned" do
        cache = 0
        run = 0
        type = MultiplyCoercer.new in_val: 2, out_val: 3
        type.default = Moduler::LazyValue.new { run += 1; 100 }

        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 600
        expect(cache).to eq 200
        expect(type.coerce_out(cache)).to eq 600
        expect(cache).to eq 200
        expect(run).to eq 1
      end

      it "When NO_VALUE is passed, and a non-caching lazy default is specified, it is cached and returned" do
        cache = 0
        run = 0
        type = MultiplyCoercer.new in_val: 2, out_val: 3
        type.default = Moduler::LazyValue.new(false) { run += 1; 100 }

        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 600
        expect(cache).to eq 0
        expect(type.coerce_out(NO_VALUE) { |v| cache=v }).to eq 600
        expect(cache).to eq 0
        expect(run).to eq 2
      end

      it "When NO_VALUE is passed, and a lazy default is specified, and no cache_proc is specified, the coerced value is returned" do
        cache = 0
        run = 0
        type = MultiplyCoercer.new in_val: 2, out_val: 3
        type.default = Moduler::LazyValue.new { run += 1; 100 }

        expect(type.coerce_out(NO_VALUE)).to eq 600
        expect(cache).to eq 0
        expect(type.coerce_out(NO_VALUE)).to eq 600
        expect(cache).to eq 0
        expect(run).to eq 2
      end
    end

    context "Lazy value" do
      #after { expect(on_set).to eq [] }

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
        type = MultiplyCoercer.new in_val: 6, out_val: 35
        cache = 0
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 }) { |v| cache=v }).to eq 21000
        expect(cache).to eq 600
        expect(type.coerce_out(cache) { |v| cache=v }).to eq 21000
        expect(cache).to eq 600
        expect(run).to eq 1
      end

      it "When given a lazy value and no cache_proc, both coercers and out coercers are run" do
        type = MultiplyCoercer.new in_val: 6, out_val: 35
        run = 0
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 21000
        expect(type.coerce_out(Moduler::LazyValue.new { run += 1; 100 })).to eq 21000
        expect(run).to eq 2
      end

      it "When given a non-caching lazy value, both coercers and out coercers are run and nothing is cached" do
        type = MultiplyCoercer.new in_val: 6, out_val: 35
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
      Moduler::Base::ValueContext.new
    end
    context "default_call" do
      context "When value is NO_VALUE" do
        before { value.set(NO_VALUE) }
        #after { expect(on_set).to eq [] }

        it "type.call() is called with no arguments" do
          expect(type.call(value)).to eq nil
        end

        it "type.call() with default returns the default value" do
          type.default = 100
          expect(type.call(value)).to eq 100
        end

        it "type.call() with default runs coercers_out but not coercers" do
          type = MultiplyCoercer.new in_val: 2, out_val: 3
          type.default = 100
          expect(type.call(value)).to eq 600
        end

        it "type.call() with lazy default caches and returns the default value" do
          type.default = Moduler::LazyValue.new { 100 }
          expect(type.call(value)).to eq 100
          expect(value.get).to eq 100
        end

        it "type.call() with lazy default caches the default value and returns the coerced default value" do
          type = MultiplyCoercer.new in_val: 2, out_val: 3
          type.default = Moduler::LazyValue.new { 100 }
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
        #expect(on_set).to eq [ 100 ]
      end

      it "type.call(value) runs coercers and returns a value with coercers_out" do
        type = MultiplyCoercer.new in_val: 2, out_val: 3
        expect(type.call(value, 100)).to eq 600
        expect(value.get).to eq 200
        #expect(on_set).to eq [ 600 ]
      end

      it "type.call(&block) sets the value to the block" do
        block = proc { 100 }
        expect(type.call(value, &block)).to eq block
        expect(value.get).to eq block
        #expect(on_set).to eq [ block ]
      end

      it "type.call(&block) with coercers and coercers_out sets the value to the block" do
        block = proc { 100 }
        type = MultiplyCoercer.new in_val: 2, out_val: 3
        expect(type.call(value, &block).call).to eq 600
        expect(value.get.call).to eq 200
        #expect(on_set.map { |x| x.call }).to eq [ 600 ]
      end
    end
  end
end
