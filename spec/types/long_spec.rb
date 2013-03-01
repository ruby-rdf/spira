require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::Long do

  context "when serializing" do
    it "should be able to serialize integers to XSD long" do
      serialized = Spira::Types::Long.serialize(5)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.long
      serialized.should == RDF::Literal.new(5, :datatype => RDF::XSD.long)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD int to integers" do
      [5, "5"].each do |num|
        value = Spira::Types::Long.unserialize(RDF::Literal.new(num, :datatype => RDF::XSD.long))
        value.should be_a Fixnum
        value.should == num.to_i
      end
    end
  end


end

