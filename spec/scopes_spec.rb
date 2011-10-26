require "prie/scope"

describe Prie::Scope do
  it "creating a scope" do
    scope = Prie::Scope.new
    scope.should be_instance_of(Prie::Scope)
  end

  it "creating a nested scope" do
    scope = Prie::Scope.new
    scope.nested = Prie::Scope.new
    scope.nested.should be_instance_of(Prie::Scope)
  end

  context "with existing scope" do
    before do
      @person = Prie::Scope.new
      @person.name = "John Galt"
      @person.address = Prie::Scope.new
      @person.address.state = "CA"
    end

    it "when accessing invalid rvalue" do
      @person.does_not_exist.should == nil
    end

    it "when accessing valid rvalue" do
      @person.name.should == "John Galt"
    end

    it "when accessing nested scope" do
      @person.address.state.should == "CA"
    end

    it "setting value in nested scope" do
      @person.address.age = 32
      @person.address.age.should == 32
    end

    it "updating existing rvalue" do
      @person.name = "John Doe" 
      @person.name.should == "John Doe"
    end

    it "updating nested scope to new scope" do
      @person.address = Prie::Scope.new
      @person.address.state.should == nil
    end
  end
end