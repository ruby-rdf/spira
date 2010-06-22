require File.dirname(__FILE__) + "/../spec_helper.rb"

describe Spira::Types::Decimal do

  context "when serializing" do
    it "should serialize decimals to XSD decimals" do
      serialized = Spira::Types::Decimal.serialize(5)
      serialized.should be_a RDF::Literal
      serialized.should have_datatype
      serialized.datatype.should == RDF::XSD.decimal
      serialized.should == RDF::Literal.new(5, :datatype => RDF::XSD.decimal)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD decimals to BigDecimals" do
      value = Spira::Types::Integer.unserialize(RDF::Literal.new(5, :datatype => RDF::XSD.decimal))
      value.should be_a BigDecimal
      value.should == BigDecimal.new('5')
    end
  end


end

