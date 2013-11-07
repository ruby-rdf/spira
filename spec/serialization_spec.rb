# -*- coding: utf-8 -*-
require "spec_helper"

describe "serialization" do
  before :all do
    class SpiraResource < Spira::Base
      property :name, :predicate => FOAF.givenName, :type => XSD.string
    end

    Spira.repository = RDF::Repository.new
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

  context "of UTF-8 literals" do
    it "should produce proper UTF-8 output" do
      res = SpiraResource.create(:name => "日本語")
      res.reload.name.should eql "日本語"
    end
  end
end
