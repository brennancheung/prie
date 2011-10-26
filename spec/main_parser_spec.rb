require "prie/lexer"
require "prie/stack_object"
require "prie/scope"
require "prie/parser"
require "prie/main_parser"

describe Prie::MainParser do
  before do
    @parser = Prie::MainParser.new
  end

  def compute(input_text)
    parsed = @parser.parse(input_text) 
    @parser.execute_loop(parsed)
    result = @parser.stack

    parsed = @parser.parse("clear")
    @parser.execute_loop(parsed)

    result
  end

  it "should support the 'run' shorthand" do
    @parser.run(" 1 2 3 + + ")
    @parser.stack.first.value.should == 6
  end

  it "should support the 'return' shorthand" do
    result = @parser.return(" 1 2 3 + + ")
    result.value.should == 6
  end

  # ---------------------------

  it "append" do
    result = compute(" [ 1 2 3 ] 4 append ")
    result.first.value.map(&:value).should == (1..4).to_a
  end

  it "append!" do
    @parser.run("[ 1 2 3 ]")
    arr = @parser.stack.pop
    @parser.stack.push(arr)
    compute("4 append!")
    arr.value.map(&:value).should == (1..4).to_a
  end

  it "and" do
    result = compute(" t t and   t f and   f t and   f f and")
    result.map(&:value).should == [true, false, false, false]
  end

  it "basic arithmetic (+ - * /)" do
    result = compute(" 1 2 3 + + 2 - 3 * 4 / ")
    result.first.value == 3
  end

  it "call (anonymous functions)" do
    result = compute(" [ 1 2 + ] call ")
    result.first.value.should == 3
  end

  it "clear" do
    result = compute(" 1 2 3 clear ")
    result.size.should == 0
  end

  it "concat" do
    result = compute(" [ 1 2 3 ] [ 4 5 6 ] concat ")
    result.first.value.map(&:value).should == (1..6).to_a
  end

  it "concat!" do
    @parser.run(" [ 1 2 3 ]")
    arr = @parser.stack.pop
    @parser.stack.push(arr)
    @parser.run(" [ 4 5 6 ] concat! ")
    arr.value.map(&:value).should == (1..6).to_a
  end

  it "count" do
    result = compute(" [ 1 2 [ 1 2 3 ] ] length")
    result.first.value.should == 3
  end

  it "drop" do
    result = compute(" 1 2 drop 3 ")
    result.map(&:value).should == [1, 3]
  end

  it "dup" do
    result = compute(" 123 dup")
    result.map(&:value).should == [123, 123]
  end

  it "each" do
    result = compute(" [ 1 2 3 ] [ 2 * ] each ")
    result.map(&:value).should == [2, 4, 6]
  end

  it "first" do
    result = compute(" [ 111 222 333 ] first")
    result.first.value.should == 111
  end

  it "if" do
    result = compute(' 1 2 = [ "yes" ] [ "no" ] if ')
    result.first.value.should == "no"

    result = compute(' 2 2 = [ "yes" ] [ "no" ] if ')
    result.first.value.should == "yes"
  end

  it "integer comparisons (< > <= >= = !=)" do
    result = compute(" 1 2 >   2 1 >   2 2 >")
    result.map(&:value).should == [false, true, false]

    result = compute(" 1 2 <   2 1 <   2 2 <")
    result.map(&:value).should == [true, false, false]

    result = compute(" 1 2 <=   2 1 <=   2 2 <=   3 2 <=")
    result.map(&:value).should == [true, false, true, false]

    result = compute(" 1 2 >=   2 1 >=   2 2 >=   3 2 >=")
    result.map(&:value).should == [false, true, true, true]

    result = compute(" 1 2 =   1 1 = ")    
    result.map(&:value).should == [false, true]

    result = compute(" 1 2 !=   1 1 != ")    
    result.map(&:value).should == [true, false]
  end

  it "join" do
    result = compute(' "ein zwei drei" w ", " join ')
    result.first.value.should == %w(ein zwei drei).join(", ")
  end

  it "last" do
    result = compute(" [ 111 222 333 ] last")
    result.first.value.should == 333
  end

  it "length" do
    result = compute(" [ 1 2 [ 1 2 3 ] ] length")
    result.first.value.should == 3
  end

  it "map" do
    result = compute(" [ 1 2 3 ] [ dup * ] map ")
    result.first.value.map(&:value).should == [1, 4, 9]
  end

  it "not" do
    result = compute("t not")
    result.first.value.should == false

    result = compute("f not")
    result.first.value.should == true
  end

  it "nth" do
    result = compute("[ 111 222 333 ] 1 nth")
    result.first.value.should == 222

    result = compute("[ 111 222 333 ] -1 nth")
    result.first.value.should == 333
  end

  it "or" do
    result = compute(" t t or   t f or   f t or   f f or")
    result.map(&:value).should == [true, true, true, false]
  end

  it "prepend" do
    result = compute(" [ 2 3 4 ] 1 prepend ")
    result.first.value.map(&:value).should == (1..4).to_a
  end

  it "prepend!" do
    @parser.run("[ 2 3 ]")
    arr = @parser.stack.pop
    @parser.stack.push(arr)
    compute("1 prepend!")
    arr.value.map(&:value).should == (1..3).to_a
  end

  it "split" do
    result = compute(' "one,two,three" "," split ')
    result.first.value.map(&:value).should == %w(one two three)
  end

  it "str-concat" do
    result = compute(' "foo" "bar" str-concat ')
    result.first.value.should == "foobar"
  end

  it "string comparison (= !=)" do
    result = compute(' "foo" "bar" = ')
    result.first.value.should == false

    result = compute(' "foo" "foo" = ')
    result.first.value.should == true

    result = compute(' "foo" "bar" != ')
    result.first.value.should == true

    result = compute(' "foo" "foo" != ')
    result.first.value.should == false
  end

  it "swap" do
    result = compute(" 1 2 swap ")
    result.map(&:value).should == [2, 1]
  end

  it "times" do
    result = compute(" 1 8 [ 2 * ] times ")
    result.first.value.should == 256
  end

  it "w" do
    result = compute(' "one two three" w ')
    result.first.value.map(&:value).should == %w(one two three)
  end

  context "scopes" do
    it "creating a scope" do
      result = compute(' "person" new-scope ')
      @parser.scopes["person"].should be_instance_of(Prie::Scope)
    end

    context "with an empty scope" do
      before do
        @parser.scopes["person"] = Prie::Scope.new
      end

      it "dynamically accessing a scope" do
        result = compute(' "person" get-scope ')      
        result.first.value.should be_instance_of(Prie::Scope)
      end

      it "directly accessing a scope" do
        result = compute(' @person ')      
        result.first.value.should be_instance_of(Prie::Scope)
      end

      it "setting a value in a scope" do
        result = compute(' @person "age" 32 << ')
        @parser.scopes["person"].age.value.should == 32
      end
    end

    context "with a populated scope" do
      before do
        @person = Prie::Scope.new
        @person.age = Prie::StackObject.new(:integer, 32)
        @person.name = Prie::StackObject.new(:string, "John Galt")
        @parser.scopes["person"] = @person
      end

      it "getting a value from a scope" do
        result = compute(' @person.age ')
        result.first.value.should == 32

        result = compute(' @person.name ')
        result.first.value.should == "John Galt"
      end

      it "getting a value from a scope dynamically" do
        result = compute(' "person" get-scope "age" >> ')
        result.first.value.should == 32
      end

      it "increment scope value without reading it" do
        compute(' @person "age" 2 inc ')
        @person.age.value.should == 34
      end

      it "decrement scope value without reading it" do
        compute(' @person "age" 2 dec ')
        @person.age.value.should == 30
      end

      it "1+ shorthand for increment with 1" do
        compute(' @person "age" 1+ ')
        @person.age.value.should == 33
      end

      it "1- shorthand for decrement with 1" do
        compute(' @person "age" 1- ')
        @person.age.value.should == 31
      end
    end

    context "with nested scopes" do
      before do
        @person = Prie::Scope.new
        @address = Prie::Scope.new
        @person.address = @address
        @address.street_address = Prie::StackObject.new(:string, "123 Main St")

        @parser.scopes["person"] = @person
      end

      it "getting a nested scope" do
        result = compute(' @person.address.street_address ')
        result.first.value.should == "123 Main St"
      end

      it "setting a nested scope" do
        compute(' @person.address "state" "CA" << ')
        @parser.scopes["person"].address.state.value.should == "CA"
      end
    end
  end
end
