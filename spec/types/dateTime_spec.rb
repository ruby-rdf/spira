require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::DateTime do

  before :all do
    @date = DateTime.now
  end

  context "when serializing" do
    it "should serialize datetimes to XSD datetimes" do
      serialized = Spira::Types::DateTime.serialize(@date)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.dateTime
      expect(serialized).to eql RDF::Literal.new(@date, datatype: RDF::XSD.dateTime)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD datetimes to datetimes" do
      value = Spira::Types::DateTime.unserialize(RDF::Literal.new(@date, datatype: RDF::XSD.dateTime))
      expect(value).to equal @date
    end
  end


end

