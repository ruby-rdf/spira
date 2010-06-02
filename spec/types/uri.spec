require File.dirname(__FILE__) + "/../spec_helper.rb"

describe Spira::Types::URI do

  before :each do
    @uri = RDF::URI('http://example.org/example')
  end

  context "when serializing" do
    it "should serialize URIs to URIs" do
      serialized = Spira::Types::URI.serialize(@uri)
      serialized.should be_a RDF::URI
      serialized.should == @uri
    end

    it "should serialize non-URIs to URIs based on the URI constructor" do
      serialized = Spira::Types::URI.serialize("test")
      serialized.should be_a RDF::URI
      serialized.should == RDF::URI('test')
    end

  end

  context "when unserializing" do
    it "should unserialize URIs to themselves" do
      value = Spira::Types::URI.unserialize(@uri)
      value.should be_a RDF::URI
      value.should == @uri
    end

    it "should unserialize non-URIs to URIs based on the URI constructor" do
      value = Spira::Types::URI.unserialize("test")
      value.should be_a RDF::URI
      value.should == RDF::URI('test')
    end
  end


end

