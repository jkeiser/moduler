RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

require 'moduler/type/basic_type'

class MultiplyCoercer < Moduler::Type::BasicType
  attribute :in_val, Numeric, :default => 1
  attribute :out_val, Numeric, :default => 1

  def coerce(value)
    case value
    when Proc
      proc { v = super(value.call); v ? v*in_val : v }
    else
      v = super(value)
      v ? v*in_val : v
    end
  end

  def coerce_out(value)
    value = super
    case value
    when Proc
      proc { v = super(value.call); v ? v*out_val : v }
    else
      v = super
      v ? (v*out_val).to_i : v
    end
  end
end

class OneBasedArray < Moduler::Type::BasicType
  def coerce(value)
    value = super(value)
    if value <= 0
      value
    else
      value-1
    end
  end
  def coerce_out(value)
    super+1
  end
end
