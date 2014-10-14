require 'moduler/type_dsl'

class Blah
  Moduler::TypeDSL::StructType.new.inline do
    attribute :foo
    attribute :bar
  end
end


x = Blah.new
x.foo = 10
puts x.foo
