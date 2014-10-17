class X
  def hi
    @x = 10
  end
  def hi2
    @x
  end
  def hi3
    remove_instance_variable(:@x)
  end
end

x = X.new
x.hi
puts x.hi2
x.hi3
x.hi3
