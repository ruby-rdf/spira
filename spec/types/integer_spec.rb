require "spec_helper"

describe Spira::Types::Integer do

  context "when serializing" do
    it "should serialize integers to XSD integers" do
      serialized = Spira::Types::Integer.serialize(5)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.integer
      expect(serialized).to eql RDF::Literal.new(5)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD integers to integers" do
      [5, "5"].each do |num|
        value = Spira::Types::Integer.unserialize(RDF::Literal.new(num, :datatype => RDF::XSD.integer))
        expect(value).to be_a Fixnum
        expect(value).to eql num.to_i
      end
    end
  end


end

