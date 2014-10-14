class A
  def foo
  end
end

a = A.new
a.instance_eval do
  class<<self
    def bar
      puts 'hi'
    end
  end
end
a.bar
puts (a.class.instance_methods - Object.instance_methods).inspect
meta = class<<a; self; end
puts (meta.instance_methods - Object.instance_methods).inspect
b = meta.new
b.bar
