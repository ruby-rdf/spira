require File.dirname(File.expand_path(__FILE__)) + '/../spec_helper'

describe Spira::Types::AnyURI do

  context "when serializing" do
    it "should be able to serialize URIs to XSD anyURI" do
      serialized = Spira::Types::AnyURI.serialize('http://host/path')
      expect(serialized).to be_a RDF::Literal
      expect(serialized).to have_datatype
      expect(serialized.datatype).to eql RDF::XSD.anyURI
      expect(serialized).to eql RDF::Literal.new('http://host/path', datatype: RDF::XSD.anyURI)
    end
  end

  context "when unserializing" do
    it "should unserialize XSD anyURI to String" do
      value = Spira::Types::AnyURI.unserialize(RDF::Literal.new('http://host/path', datatype: RDF::XSD.anyURI))
      expect(value).to be_a String
      expect(value).to eql 'http://host/path'
    end
  end


end

