require "spec_helper"

describe Spira::Types::NonPositiveInteger do

  context "when serializing" do
    it "should serialize integers to XSD non positive integers" do
      serialized = Spira::Types::NonPositiveInteger.serialize(-5)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.nonPositiveInteger
      expect(serialized).to eq RDF::Literal.new(-5)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD non positive integers to integers" do
      [-5, "-5"].each do |num|
        value = Spira::Types::NonPositiveInteger.unserialize(RDF::Literal.new(num, :datatype => RDF::XSD.nonPositiveInteger))
        expect(value).to be_a Fixnum
        expect(value).to eql num.to_i
      end
    end
  end


end

