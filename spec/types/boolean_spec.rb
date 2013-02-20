require "spec_helper"

describe Spira::Types::Boolean do

  context "when serializing" do
    it "should serialize booleans to XSD booleans" do
      serialized = Spira::Types::Boolean.serialize(true)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.boolean
      serialized.should == RDF::Literal.new(true)
    end

    it "should serialize true-equivalents to XSD booleans" do
      serialized = Spira::Types::Boolean.serialize(15)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.boolean
      serialized.should == RDF::Literal.new(true)
    end

    it "should serialize false-equivalents to XSD booleans" do
      serialized = Spira::Types::Boolean.serialize(nil)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.boolean
      serialized.should == RDF::Literal.new(false)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD booleans to booleans" do
      value = Spira::Types::Boolean.unserialize(RDF::Literal.new(true, :datatype => RDF::XSD.boolean))
      value.should equal true
      value = Spira::Types::Boolean.unserialize(RDF::Literal.new(false, :datatype => RDF::XSD.boolean))
      value.should equal false
    end
  end


end

