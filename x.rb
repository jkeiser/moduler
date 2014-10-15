require 'moduler/type'

class Blah
  Moduler::Type.inline do
    attribute :foo
    attribute :bar
  end
end


x = Blah.new
x.foo = 10
puts x.foo
