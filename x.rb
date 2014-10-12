class X
end
X.instance_eval do
  def blah
   @blah
  end
  @blah = 10
end

puts X.blah
