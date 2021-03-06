require 'support/spec_support'
require 'moduler/value/lazy'
require 'moduler/type/array_type'

describe Moduler::Type::ArrayType do
  shared_context "it behaves exactly like a normal array" do
    it "size works" do
      expect(array.size).to eq 3
    end
    it "each works" do
      i = 1
      array.each { |val| expect(val).to eq i; i+=1 }
    end
    it "each_with_index works" do
      i = 1
      array.each_with_index { |val,index| expect(val).to eq i; expect(index).to eq i-1; i+=1 }
    end
    it "to_a works" do
      expect(array.to_a).to eq [1,2,3]
    end
    it "== works" do
      expect(array == [1,2,3]).to eq true
      expect(array == [8,9,10]).to eq false
    end
    it "[] works" do
      expect(array[0]).to eq 1
      expect(array[1]).to eq 2
      expect(array[2]).to eq 3
    end
    it "[] with negative range works" do
      expect(array[-3]).to eq 1
      expect(array[-2]).to eq 2
      expect(array[-1]).to eq 3
    end
    it "[] out of range returns nil" do
      expect(array[3]).to be_nil
      expect(array[-4]).to be_nil
    end
    it "[a..b] works" do
      expect(array[1..2]).to eq [2,3]
    end
    it "[a..b] works with negative range" do
      expect(array[-2..-1]).to eq [2,3]
    end
    it "[a..b] works out of range" do
      expect(array[8..9]).to eq nil
    end
    it "[a..b] works with partial range" do
      expect(array[2..8]).to eq [3]
    end
    it "[]= works" do
      expect(array[1] = 10).to eq 10
      expect(array).to eq [1,10,3]
    end
    it "[]= with negative range works" do
      expect(array[-1] = 10).to eq 10
      expect(array).to eq [1,2,10]
    end
    it "[]= out of range creates nil values" do
      expect(array[5] = 10).to eq 10
      expect(array).to eq [1,2,3,nil,nil,10]
    end
    it "[a..b]=[...] works" do
      expect(array[1..2] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,4,5,6]
      expect(array[1..2] = [7,8,9]).to eq [7,8,9]
      expect(array).to eq [1,7,8,9,6]
    end
    it "[-a..-b]=[...] works" do
      expect(array[-2..-1] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,4,5,6]
      expect(array[-3..-2] = [7,8,9]).to eq [7,8,9]
      expect(array).to eq [1,7,8,9,6]
    end
    it "[a..b]=[...] with indexes out of range works" do
      expect(array[4..8] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,2,3,nil,4,5,6]
    end
    it "[a..b]=[...] with indexes partially out of range works" do
      expect(array[2..6] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,2,4,5,6]
    end
    it "<< works" do
      expect(array << 10).to eq [1,2,3,10]
      expect(array).to eq [1,2,3,10]
    end
    it "unshift works" do
      expect(array.unshift(10)).to eq [10,1,2,3]
      expect(array).to eq [10,1,2,3]
    end
    it "shift works" do
      expect(array.shift).to eq 1
      expect(array).to eq [2,3]
    end
    it "shift from empty array works" do
      expect(array.shift).to eq 1
      expect(array.shift).to eq 2
      expect(array.shift).to eq 3
      expect(array.shift).to be_nil
    end
    it "push works" do
      expect(array.push(10)).to eq [1,2,3,10]
      expect(array).to eq [1,2,3,10]
    end
    it "pop works" do
      expect(array.pop).to eq 3
      expect(array).to eq [1,2]
    end
    it "pop from empty array works" do
      expect(array.pop).to eq 3
      expect(array.pop).to eq 2
      expect(array.pop).to eq 1
      expect(array.pop).to be_nil
    end
    it "insert works" do
      expect(array.insert(2, 10)).to eq [1,2,10,3]
      expect(array).to eq [1,2,10,3]
    end
    it "insert with negative values works" do
      expect(array.insert(-2, 10)).to eq [1,2,10,3]
      expect(array).to eq [1,2,10,3]
    end
    it "insert with out of bound values raises an error" do
      expect(array.insert(6, 10)).to eq [1,2,3,nil,nil,nil,10]
      expect(array).to eq [1,2,3,nil,nil,nil,10]
    end
    it "delete_at works" do
      expect(array.delete_at(1)).to eq 2
      expect(array).to eq [1,3]
    end
    it "delete_at with negative range works" do
      expect(array.delete_at(-2)).to eq 2
      expect(array).to eq [1,3]
    end
    it "delete_at with out of bound values raises an error" do
      expect(array.delete_at(5)).to eq nil
    end
  end

  shared_context "it behaves like a one-based array" do
    it "size works" do
      expect(array.size).to eq 3
    end
    it "each works" do
      i = 1
      array.each { |val| expect(val).to eq i; i+=1 }
    end
    it "each_with_index works" do
      i = 1
      array.each_with_index { |val,index| expect(val).to eq i; expect(index).to eq i; i+=1 }
    end
    it "to_a works" do
      expect(array.to_a).to eq [1,2,3]
    end
    it "== works" do
      expect(array == [1,2,3]).to eq true
      expect(array == [8,9,10]).to eq false
    end
    it "[] works" do
      expect(array[1]).to eq 1
      expect(array[2]).to eq 2
      expect(array[3]).to eq 3
    end
    it "[] with negative range works" do
      expect(array[-3]).to eq 1
      expect(array[-2]).to eq 2
      expect(array[-1]).to eq 3
    end
    it "[] out of range returns nil" do
      expect(array[4]).to be_nil
      expect(array[-4]).to be_nil
    end
    it "[a..b] works" do
      expect(array[2..3]).to eq [2,3]
    end
    it "[a..b] works with negative range" do
      expect(array[-2..-1]).to eq [2,3]
    end
    it "[a..b] works out of range" do
      expect(array[9..10]).to eq nil
    end
    it "[a..b] works with partial range" do
      expect(array[3..9]).to eq [3]
    end
    it "[]= works" do
      expect(array[2] = 10).to eq 10
      expect(array).to eq [1,10,3]
    end
    it "[]= with negative range works" do
      expect(array[-1] = 10).to eq 10
      expect(array).to eq [1,2,10]
    end
    it "[]= out of range creates nil values" do
      expect(array[6] = 10).to eq 10
      expect(array).to eq [1,2,3,nil,nil,10]
    end
    it "[a..b]=[...] works" do
      expect(array[2..3] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,4,5,6]
      expect(array[2..3] = [7,8,9]).to eq [7,8,9]
      expect(array).to eq [1,7,8,9,6]
    end
    it "[-a..-b]=[...] works" do
      expect(array[-2..-1] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,4,5,6]
      expect(array[-3..-2] = [7,8,9]).to eq [7,8,9]
      expect(array).to eq [1,7,8,9,6]
    end
    it "[a..b]=[...] with indexes out of range works" do
      expect(array[5..9] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,2,3,nil,4,5,6]
    end
    it "[a..b]=[...] with indexes partially out of range works" do
      expect(array[3..7] = [4,5,6]).to eq [4,5,6]
      expect(array).to eq [1,2,4,5,6]
    end
    it "<< works" do
      expect(array << 10).to eq [1,2,3,10]
      expect(array).to eq [1,2,3,10]
    end
    it "unshift works" do
      expect(array.unshift(10)).to eq [10,1,2,3]
      expect(array).to eq [10,1,2,3]
    end
    it "shift works" do
      expect(array.shift).to eq 1
      expect(array).to eq [2,3]
    end
    it "shift from empty array works" do
      expect(array.shift).to eq 1
      expect(array.shift).to eq 2
      expect(array.shift).to eq 3
      expect(array.shift).to be_nil
    end
    it "push works" do
      expect(array.push(10)).to eq [1,2,3,10]
      expect(array).to eq [1,2,3,10]
    end
    it "pop works" do
      expect(array.pop).to eq 3
      expect(array).to eq [1,2]
    end
    it "pop from empty array works" do
      expect(array.pop).to eq 3
      expect(array.pop).to eq 2
      expect(array.pop).to eq 1
      expect(array.pop).to be_nil
    end
    it "insert works" do
      expect(array.insert(3, 10)).to eq [1,2,10,3]
      expect(array).to eq [1,2,10,3]
    end
    it "insert with negative values works" do
      expect(array.insert(-2, 10)).to eq [1,2,10,3]
      expect(array).to eq [1,2,10,3]
    end
    it "insert with out of bound values raises an error" do
      expect(array.insert(7, 10)).to eq [1,2,3,nil,nil,nil,10]
      expect(array).to eq [1,2,3,nil,nil,nil,10]
    end
    it "delete_at works" do
      expect(array.delete_at(2)).to eq 2
      expect(array).to eq [1,3]
    end
    it "delete_at with negative range works" do
      expect(array.delete_at(-2)).to eq 2
      expect(array).to eq [1,3]
    end
    it "delete_at with out of bound values raises an error" do
      expect(array.delete_at(6)).to eq nil
    end
  end

  context "With a normal array" do
    include_context "it behaves exactly like a normal array" do
      let(:array) { [1,2,3] }
    end
  end

  let(:instance) { type.from_raw(type.to_raw([1,2,3], nil), nil) }
  context "With an empty type" do
    let(:type) { Moduler::Type::ArrayType.new }

    include_context "it behaves exactly like a normal array" do
      let(:array) { instance }
    end
  end

  context "With an index type" do
    let(:type) { Moduler::Type::ArrayType.new index_type: OneBasedArray.new }

    include_context "it behaves like a one-based array" do
      let(:array) { instance }
    end
  end

  context "With an element type" do
    let(:type) { Moduler::Type::ArrayType.new element_type: MultiplyCoercer.new(in_val: 2, out_val: 0.5) }

    include_context "it behaves exactly like a normal array" do
      let(:array) { instance }
      after do
        array.raw.each do |v|
          if v
            expect(v%2).to eq 0
          end
        end
      end
    end

    it "Stores values internally multiplied" do
      expect(array.raw).to eq [ 2, 4, 6 ]
    end

    context "And an index type" do
      let(:type) { Moduler::Type::ArrayType.new index_type: OneBasedArray.new, element_type: MultiplyCoercer.new(in_val: 2, out_val: 0.5) }

      include_context "it behaves like a one-based array" do
        let(:array) { instance }
        after do
          array.raw.each do |v|
            if v
              expect(v%2).to eq 0
            end
          end
        end
      end

      it "Stores values internally multiplied" do
        expect(array.raw).to eq [ 2, 4, 6 ]
      end
    end
  end
end
