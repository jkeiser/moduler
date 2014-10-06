module X
  def blah
    puts 'blah'
  end
end

class Y
  include X
end

module Z
  include X
end

puts Y.ancestors
puts Z.ancestors
