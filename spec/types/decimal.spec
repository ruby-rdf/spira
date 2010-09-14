require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::Decimal do

  context "when serializing" do
    it "should serialize decimals to XSD decimals" do
      serialized = Spira::Types::Decimal.serialize(5.15)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.decimal
      serialized.should == RDF::Literal.new(5.15, :datatype => RDF::XSD.decimal)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD decimals to BigDecimals" do
      value = Spira::Types::Decimal.unserialize(RDF::Literal.new(5.15, :datatype => RDF::XSD.decimal))
      value.should be_a BigDecimal
      value.should == BigDecimal.new('5.15')
    end
  end

  # BigDecimal has a silly default to_s, which this test makes sure we are avoiding
  context "when round tripping" do
    it "should serialize to the original value after unserializing" do
      literal = RDF::Literal.new(5.15, :datatype => RDF::XSD.decimal)
      unserialized = Spira::Types::Decimal.unserialize(literal)
      serialized = Spira::Types::Decimal.serialize(unserialized)
      serialized.should == literal
    end
  end

end

