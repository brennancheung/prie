require 'prie/stack_object'

describe Prie::StackObject do
  it "should take a type and value to initialize" do
    so = Prie::StackObject.new(:word, "concat")
    so.should be_an_instance_of(Prie::StackObject)
  end

  it "should raise an error with invalid number of initialize params" do
    expect { so = Prie::StackObject.new }.to raise_error(ArgumentError)
    expect { so = Prie::StackObject.new(:one) }.to raise_error(ArgumentError)
    expect { so = Prie::StackObject.new(:one, :two, :three) }.to raise_error(ArgumentError)
  end

  it "should set the type on integers" do
    so = Prie::StackObject.new(:word, "123")
    so.type.should == :integer
  end

  it "should set the type on floats" do
    so = Prie::StackObject.new(:word, "123.45")
    so.type.should == :float
  end
end