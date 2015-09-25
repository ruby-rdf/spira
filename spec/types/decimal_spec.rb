require "spec_helper"

describe Spira::Types::Decimal do

  context "when serializing" do
    it "should serialize decimals to XSD decimals" do
      serialized = Spira::Types::Decimal.serialize(5.15)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.decimal
      expect(serialized).to eql RDF::Literal.new(5.15, :datatype => RDF::XSD.decimal)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD decimals to BigDecimals" do
      value = Spira::Types::Decimal.unserialize(RDF::Literal.new(5.15, :datatype => RDF::XSD.decimal))
      expect(value).to be_a BigDecimal
      expect(value).to eql BigDecimal.new('5.15')
    end
  end

  # BigDecimal has a silly default to_s, which this test makes sure we are avoiding
  context "when round tripping" do
    it "should serialize to the original value after unserializing" do
      literal = RDF::Literal.new(5.15, :datatype => RDF::XSD.decimal)
      unserialized = Spira::Types::Decimal.unserialize(literal)
      serialized = Spira::Types::Decimal.serialize(unserialized)
      expect(serialized).to eql literal
    end
  end

end

