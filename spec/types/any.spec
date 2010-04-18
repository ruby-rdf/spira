require File.dirname(__FILE__) + "/../spec_helper.rb"

describe Spira::Types::Any do

  # this spec is going to be necessarily loose.  The 'Any' type is defined to
  # use RDF.rb's automatic RDF Literal boxing and unboxing, which may or may
  # not change between verions.
  #
  context "when serializing" do
    it "should serialize things to RDF Literals" do
      serialized = Spira::Types::Integer.serialize(15)
      serialized.should be_a RDF::Literal
      serialized = Spira::Types::Integer.serialize("test")
      serialized.should be_a RDF::Literal
    end

    it "should fail to serialize collections" do
      pending "Determine how to handle type errors"
    end
  end

  context "when unserializing" do
    it "should unserialize to ruby types" do
      value = Spira::Types::Integer.unserialize(RDF::Literal.new(5, :datatype => RDF::XSD.integer))
      value.should == 5
      value = Spira::Types::Integer.unserialize(RDF::Literal.new("a string"))
      value.should == "a string"
    end
  end


end

