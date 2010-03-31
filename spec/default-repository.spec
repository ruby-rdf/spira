require File.dirname(__FILE__) + "/spec_helper.rb"

# This test is a simple model that uses the :default repository

describe "The :default repository" do

  context "The event fixture" do

    before :all do
      require 'event'
    end

    it "should be instantiable" do
      lambda {x = Event.create RDF::URI.new 'http://example.org/people/bob'}.should_not raise_error
    end

    it "should know its source" do
      Event.repository.should be_a RDF::Repository
    end

    it "should raise an error to access a repository for a class with a defined default which does not exist" do
      lambda { Stadium.repository }.should raise_error RuntimeError
    end
  end
end
