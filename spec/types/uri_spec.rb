require "spec_helper"

describe Spira::Types::URI do

  before :each do
    @uri = RDF::URI('http://example.org/example')
  end

  context "when serializing" do
    it "should serialize URIs to URIs" do
      serialized = Spira::Types::URI.serialize(@uri)
      expect(serialized).to be_a RDF::URI
      expect(serialized).to eql @uri
    end

    it "should serialize non-URIs to URIs based on the URI constructor" do
      serialized = Spira::Types::URI.serialize("test")
      expect(serialized).to be_a RDF::URI
      expect(serialized).to eql RDF::URI('test')
    end

  end

  context "when unserializing" do
    it "should unserialize URIs to themselves" do
      value = Spira::Types::URI.unserialize(@uri)
      expect(value).to be_a RDF::URI
      expect(value).to eql @uri
    end

    it "should unserialize non-URIs to URIs based on the URI constructor" do
      value = Spira::Types::URI.unserialize("test")
      expect(value).to be_a RDF::URI
      expect(value).to eql RDF::URI('test')
    end
  end


end

