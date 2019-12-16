# -*- coding: utf-8 -*-
require "spec_helper"

describe "serialization" do
  before :all do
    class SpiraResource < Spira::Base
      property :name, predicate: RDF::Vocab::FOAF.givenName, type: XSD.string
    end

    Spira.repository = RDF::Repository.new
  end

  it "should serialize a spira resource into its subject" do
    res = SpiraResource.for RDF::URI.new("http://example.com/resources/res1")

    serialized = SpiraResource.serialize(res)
    expect(serialized).not_to be_nil
    expect(serialized).to eql res.subject
  end

  it "should serialize a blank ruby object into nil" do
    expect(SpiraResource.serialize("")).to be_nil
  end

  it "should raise TypeError exception when trying to serialize an object it cannot serialize" do
    expect { SpiraResource.serialize(1) }.to raise_error TypeError
  end

  context "of UTF-8 literals" do
    it "should produce proper UTF-8 output" do
      res = SpiraResource.create(name: "日本語")
      expect(res.reload.name).to eql "日本語"
    end
  end
end
