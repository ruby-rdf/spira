require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::GYear do

  context "when serializing" do
    it "should be able to serialize integers to XSD gYear" do
      serialized = Spira::Types::GYear.serialize(2005)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.gYear
      serialized.should == RDF::Literal.new(2005, :datatype => RDF::XSD.gYear)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD gYear to integers" do
      value = Spira::Types::Int.unserialize(RDF::Literal.new(2005, :datatype => RDF::XSD.gYear))
      value.should be_a Integer
      value.should == 2005
    end
  end


end

