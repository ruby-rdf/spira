require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::GYear do

  context "when serializing" do
    it "should be able to serialize integers to XSD gYear" do
      serialized = Spira::Types::GYear.serialize(2005)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.gYear
      expect(serialized).to eql RDF::Literal.new(2005, datatype: RDF::XSD.gYear)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD gYear to integers" do
      value = Spira::Types::Int.unserialize(RDF::Literal.new(2005, datatype: RDF::XSD.gYear))
      expect(value).to be_a Integer
      expect(value).to eql 2005
    end
  end


end

