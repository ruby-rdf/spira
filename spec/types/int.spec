require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::Int do

  context "when serializing" do
    it "should be able to serialize integers to XSD int" do
      serialized = Spira::Types::Int.serialize(5)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.int
      serialized.should == RDF::Literal.new(5, :datatype => RDF::XSD.int)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD int to integers" do
      value = Spira::Types::Int.unserialize(RDF::Literal.new(5, :datatype => RDF::XSD.int))
      value.should be_a Fixnum
      value.should == 5
    end
  end


end

