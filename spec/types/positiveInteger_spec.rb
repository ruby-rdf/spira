require "spec_helper"

describe Spira::Types::PositiveInteger do

  context "when serializing" do
    it "should serialize integers to XSD negative integers" do
      serialized = Spira::Types::PositiveInteger.serialize(5)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.positiveInteger
      expect(serialized).to eq RDF::Literal.new(5)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD non negative integers to integers" do
      [5, "5"].each do |num|
        value = Spira::Types::PositiveInteger.unserialize(RDF::Literal.new(num, datatype: RDF::XSD.positiveInteger))
        expect(value).to be_a Integer
        expect(value).to eql num.to_i
      end
    end
  end


end

