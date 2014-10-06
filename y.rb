class X
  def self.inherited(other)
    puts "#{self}.extended(#{other})"
  end
  def a
    puts visibility
  end
end

class Y < X
end

class Z < Y
end

X.new.a
