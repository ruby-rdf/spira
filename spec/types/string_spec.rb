require "spec_helper"

describe Spira::Types::String do

  context "when serializing" do
    it "should serialize strings to XSD strings" do
      serialized = Spira::Types::String.serialize("a string")
      serialized.should be_a RDF::Literal
      serialized.should == RDF::Literal.new("a string")
    end

    it "should serialize other types to XSD strings" do
      serialized = Spira::Types::String.serialize(5)
      serialized.should be_a RDF::Literal
      serialized.should == RDF::Literal.new("5")
    end
  end

  context "when unserializing" do
    it "should unserialize XSD strings to strings" do
      value = Spira::Types::String.unserialize(RDF::Literal.new("a string", :datatype => RDF::XSD.string))
      value.should be_a String
      value.should == "a string"
    end

    it "should unserialize anything else to a string" do
      value = Spira::Types::String.unserialize(RDF::Literal.new(5, :datatype => RDF::XSD.integer))
      value.should be_a String
      value.should == "5"
    end
  end


end

