require "spec_helper"

describe Spira::Types::NonNegativeInteger do

  context "when serializing" do
    it "should serialize integers to XSD non negative integers" do
      serialized = Spira::Types::NonNegativeInteger.serialize(5)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.nonNegativeInteger
      serialized.should == RDF::Literal.new(5)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD non negative integers to integers" do
      [5, "5"].each do |num|
        value = Spira::Types::NonNegativeInteger.unserialize(RDF::Literal.new(num, :datatype => RDF::XSD.nonNegativeInteger))
        value.should be_a Fixnum
        value.should == num.to_i
      end
    end
  end


end

