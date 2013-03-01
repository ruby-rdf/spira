require "spec_helper"

describe Spira::Types::NonPositiveInteger do

  context "when serializing" do
    it "should serialize integers to XSD non positive integers" do
      serialized = Spira::Types::NonPositiveInteger.serialize(-5)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.nonPositiveInteger
      serialized.should == RDF::Literal.new(-5)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD non positive integers to integers" do
      [-5, "-5"].each do |num|
        value = Spira::Types::NonPositiveInteger.unserialize(RDF::Literal.new(num, :datatype => RDF::XSD.nonPositiveInteger))
        value.should be_a Fixnum
        value.should == num.to_i
      end
    end
  end


end

