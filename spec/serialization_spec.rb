require "spec_helper"

describe "serialization" do
  before :all do
    class SpiraResource < Spira::Base; end
  end

  it "should serialize a spira resource into its subject" do
    res = SpiraResource.for RDF::URI.new("http://example.com/resources/res1")

    serialized = SpiraResource.serialize(res)
    serialized.should_not be_nil
    serialized.should eql res.subject
  end

  it "should serialize a blank ruby object into nil" do
    SpiraResource.serialize("").should be_nil
  end

  it "should raise TypeError exception when trying to serialize an object it cannot serialize" do
    lambda { SpiraResource.serialize(1) }.should raise_error TypeError
  end
end
