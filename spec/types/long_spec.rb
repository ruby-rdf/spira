require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::Long do

  context "when serializing" do
    it "should be able to serialize integers to XSD long" do
      serialized = Spira::Types::Long.serialize(5)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.long
      expect(serialized).to eql RDF::Literal.new(5, datatype: RDF::XSD.long)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD int to integers" do
      [5, "5"].each do |num|
        value = Spira::Types::Long.unserialize(RDF::Literal.new(num, datatype: RDF::XSD.long))
        expect(value).to be_a Integer
        expect(value).to eql num.to_i
      end
    end
  end


end

