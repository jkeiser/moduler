require 'moduler/path'

x = Moduler::Path::Windows.new('a')
puts x
y = x + 'b'
puts y
puts Moduler::Path::Windows.new('//a/b/c/d').cleanpath
