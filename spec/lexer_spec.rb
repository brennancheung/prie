require "prie/lexer"

describe Prie::Lexer do
  it "should initialize with a string and set the cursor to 0" do
    lexer = Prie::Lexer.new("1 2 3")
    lexer.should be_an_instance_of(Prie::Lexer)
    lexer.cursor.should == 0
  end

  it "should raise an exception when no string is passed to initialize" do
    expect { Prie::Lexer.new }.should raise_error(ArgumentError)
    expect { Prie::Lexer.new("one", "two") }.should raise_error(ArgumentError)
  end

  it "next_char should return the next char and advance the cursor" do
    lexer = Prie::Lexer.new("123")
    lexer.next_char.should == "1"
    lexer.next_char.should == "2"
    lexer.next_char.should == "3"
    lexer.cursor.should == 3
  end
end
