require "spec_helper"

describe Spira::Types::Double do

  context "when serializing" do
    it "should serialize floats to XSD doubles" do
      serialized = Spira::Types::Double.serialize(5.0)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.double
      expect(serialized).to eql RDF::Literal.new(5.0)
    end

    it "should serialize integers to XSD doubles" do
      serialized = Spira::Types::Double.serialize(5)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.double
      expect(serialized).to eql RDF::Literal.new(5.0)
    end

  end

  context "when unserializing" do
    it "should unserialize XSD doubles to floats" do
      value = Spira::Types::Double.unserialize(RDF::Literal.new(5, :datatype => RDF::XSD.double))
      expect(value).to be_a Float
      expect(value).to eql 5.0
    end
  end


end

