require "spec_helper"

describe Spira::Types::Integer do

  context "when serializing" do
    it "should serialize integers to XSD integers" do
      serialized = Spira::Types::Integer.serialize(5)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.integer
      serialized.should == RDF::Literal.new(5)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD integers to integers" do
      [5, "5"].each do |num|
        value = Spira::Types::Integer.unserialize(RDF::Literal.new(num, :datatype => RDF::XSD.integer))
        value.should be_a Fixnum
        value.should == num.to_i
      end
    end
  end


end

