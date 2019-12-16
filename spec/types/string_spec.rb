require "spec_helper"

describe Spira::Types::String do

  context "when serializing" do
    it "should serialize strings to XSD strings" do
      serialized = Spira::Types::String.serialize("a string")
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to eql RDF::Literal.new("a string")
    end

    it "should serialize other types to XSD strings" do
      serialized = Spira::Types::String.serialize(5)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to eql RDF::Literal.new("5")
    end
  end

  context "when unserializing" do
    it "should unserialize XSD strings to strings" do
      value = Spira::Types::String.unserialize(RDF::Literal.new("a string", datatype: RDF::XSD.string))
      expect(value).to be_a String
      expect(value).to eql "a string"
    end

    it "should unserialize anything else to a string" do
      value = Spira::Types::String.unserialize(RDF::Literal.new(5, datatype: RDF::XSD.integer))
      expect(value).to be_a String
      expect(value).to eql "5"
    end
  end


end

