require "spec_helper"

describe Spira::Types::Boolean do

  context "when serializing" do
    it "should serialize booleans to XSD booleans" do
      serialized = Spira::Types::Boolean.serialize(true)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.boolean
      expect(serialized).to eql RDF::Literal.new(true)
    end

    it "should serialize true-equivalents to XSD booleans" do
      serialized = Spira::Types::Boolean.serialize(15)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.boolean
      expect(serialized).to eql RDF::Literal.new(true)
    end

    it "should serialize false-equivalents to XSD booleans" do
      serialized = Spira::Types::Boolean.serialize(nil)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.boolean
      expect(serialized).to eql RDF::Literal.new(false)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD booleans to booleans" do
      value = Spira::Types::Boolean.unserialize(RDF::Literal.new(true, datatype: RDF::XSD.boolean))
      expect(value).to equal true
      value = Spira::Types::Boolean.unserialize(RDF::Literal.new(false, datatype: RDF::XSD.boolean))
      expect(value).to equal false
    end
  end


end

