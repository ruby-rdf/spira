require File.dirname(__FILE__) + "/spec_helper.rb"

# Fixture to test :default repository loading

class Event
  include Spira::Resource

  property :name, :predicate => DC.title

end

class Stadium
  include Spira::Resource

  property :name, :predicate => DC.title

  default_source :stadium

end

# This test is a simple model that uses the :default repository

describe "The :default repository" do

  context "Adding a default repository" do

    before :all do
      @repo = RDF::Repository.new
    end

    it "should fail to add something that is not a repository" do
      lambda {Spira.add_repository(:bad_arguments, 'a string, for example')}.should raise_error ArgumentError
    end

    it "should construct a repository from a class name" do
      lambda {Spira.add_repository(:test_class_name, ::RDF::Repository)}.should_not raise_error
      Spira.repository(:test_class_name).should be_a ::RDF::Repository
    end

    it "should construct a repository from a class name and constructor arguments" do
      lambda {Spira.add_repository(:test_class_args, ::RDF::Repository, :uri => ::RDF::DC.title)}.should_not raise_error
      Spira.repository(:test_class_args).should be_a ::RDF::Repository
      Spira.repository(:test_class_args).uri.should == ::RDF::DC.title
    end

    it "should add a default repository for classes without one" do
      lambda {Spira.add_repository(:default, @repo)}.should_not raise_error
      Event.repository.should equal @repo
    end

    it "should allow updating of the default repository" do
      @new_repo = RDF::Repository.new
      Spira.add_repository(:default, @new_repo)
      Event.repository.should equal @new_repo
    end


  end

  context "The event fixture" do

    before :all do
    end

    it "should be instantiable" do
      lambda {x = Event.for RDF::URI.new 'http://example.org/people/bob'}.should_not raise_error
    end

    it "should know its source" do
      Event.repository.should be_a RDF::Repository
    end

    it "should return nil for a repository which does not exist" do
      Stadium.repository.should == nil
    end

    it "should raise an error to call class.find for a class with a defined default which does not exist" do
      lambda { Stadium.for 'test'}.should raise_error RuntimeError
    end

  end
end
