require "spec_helper"

describe Spira::Types::Float do

  context "when serializing" do
    it "should serialize floats to XSD floats" do
      serialized = Spira::Types::Float.serialize(5.0)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.float
    end

    it "should serialize integers to XSD floats" do
      serialized = Spira::Types::Float.serialize(5)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.float
    end

  end

  context "when unserializing" do
    it "should unserialize XSD floats to floats" do
      value = Spira::Types::Float.unserialize(RDF::Literal.new(5, datatype: RDF::XSD.float))
      expect(value).to be_a Float
      expect(value).to eql 5.0
    end
  end


end

