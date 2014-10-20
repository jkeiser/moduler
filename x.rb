class X
  def hi
    @foo = 10
  end
  def lo
    remove_instance_variable(:@foo)
  end
end

x = X.new
puts x.hi
puts x.lo
