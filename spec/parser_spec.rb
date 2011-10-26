require "prie/parser"

describe Prie::Parser do
  it "should raise an exception when additional init params are passed" do
    expect { Prie::Parser.new("additional", "params") }.should raise_error(ArgumentError)
  end

  context "with initialized parser" do
    before do
      @parser = Prie::Parser.new
    end

    it "should initialize" do
      @parser.should be_an_instance_of(Prie::Parser)
    end

    it "should parse input" do
      @parser.parse("1 2 3").size == 3
    end

    context "with result of parsed input text" do
      before do
        @result = @parser.parse('123 "this is a string" t dup')
      end

      it "should consist of all StackObject's" do
        @result.all? {|so| so.class.should == Prie::StackObject}
      end

      it "should consist of the correct types" do
        @result.map(&:type).should == [:integer, :string, :boolean, :word]
      end

      it "should clear the stack when calling clear" do
        @parser.clear
        @parser.stack.should == []
      end
    end
  end
end
