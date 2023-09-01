require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::Time do

  let!(:time) {Time.now}

  context "when serializing" do
    it "should serialize times to XSD times" do
      serialized = Spira::Types::Time.serialize(time)
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.time
      expect(serialized).to eql RDF::Literal.new(time, datatype: RDF::XSD.time)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD times to times" do
      value = Spira::Types::Time.unserialize(RDF::Literal.new(time, datatype: RDF::XSD.time))
      expect(value.strftime("%H:%M:%S")).to eq time.strftime("%H:%M:%S")
    end
  end
end