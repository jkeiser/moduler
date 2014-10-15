RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

require 'moduler/type/basic_type'

class MultiplyCoercer < Moduler::Type::BasicType
  attribute :in_val, Fixnum, :default => 1
  attribute :out_val, Fixnum, :default => 1

  def coerce(value)
    case value
    when Moduler::LazyValue
      value
    when Proc
      proc { super(value.call)*in_val }
    else
      super(value)*in_val
    end
  end

  def coerce_out(value)
    value = super(value)
    case value
    when Proc
      proc { super(value.call)*out_val }
    else
      super(value)*out_val
    end
  end
end

class OneBasedArray < Moduler::Type::BasicType
  def coerce(value)
    value = super(value)
    value.is_a?(Moduler::LazyValue) ? value : value-1
  end
  def coerce_out(value)
    super(value)+1
  end
end
