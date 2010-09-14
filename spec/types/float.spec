require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::Float do

  context "when serializing" do
    it "should serialize floats to XSD floats" do
      serialized = Spira::Types::Float.serialize(5.0)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.double
      serialized.should == RDF::Literal.new(5.0)
    end

    it "should serialize integers to XSD floats" do
      serialized = Spira::Types::Float.serialize(5)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.double
      serialized.should == RDF::Literal.new(5.0)
    end

  end

  context "when unserializing" do
    it "should unserialize XSD floats to floats" do
      value = Spira::Types::Float.unserialize(RDF::Literal.new(5, :datatype => RDF::XSD.float))
      value.should be_a Float
      value.should == 5.0
    end

    it "should unserialize XSD doubles to floats" do
      value = Spira::Types::Float.unserialize(RDF::Literal.new(5, :datatype => RDF::XSD.double))
      value.should be_a Float
      value.should == 5.0
    end
  end


end

