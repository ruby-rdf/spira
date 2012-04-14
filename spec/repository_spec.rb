require "spec_helper"

# Fixture to test :default repository loading

describe Spira do

  context "when registering repositories" do

    before :all do
      @repo = RDF::Repository.new
      class ::Event < Spira::Base
        property :name, :predicate => DC.title
      end

      class ::Stadium < Spira::Base
        configure :repository_name => :stadium
        property :name, :predicate => DC.title
      end
    end

    before :each do
      Spira.clear_repositories!
    end

    context "in a different thread" do
      before :each do
        Spira.add_repository :default, @repo
      end

      it "should be available" do
        repo = nil

        t = Thread.new {
          repo = Spira.repository(:default)
        }
        t.join

        repo.should eql(@repo)
      end
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

    it "should allow clearing all repositories" do
      Spira.should respond_to :clear_repositories!
      Spira.add_repository(:test_clear, RDF::Repository.new)
      Spira.clear_repositories!
      Spira.repository(:test_clear).should be_nil
    end

  end

  context "classes using the default repository" do

    context "without a set repository" do
      before :each do
        Spira.clear_repositories!
        @event = Event.for(RDF::URI.new('http://example.org/events/this-one'))
      end

      it "should return nil for a repository which does not exist" do
        Event.repository.should be_nil
      end

      it "should raise an error when accessing an attribute" do
        lambda { @event.name }.should raise_error
      end

      it "should raise an error to call instance#save" do
        @event.name = "test"
        lambda { @event.save }.should raise_error
      end

      it "should raise an error to call instance#destroy" do
        lambda { @event.destroy }.should raise_error
      end

    end

    context "with a set repository" do
      before :each do
        Spira.clear_repositories!
        @repo = RDF::Repository.new
        Spira.add_repository(:default, @repo)
      end

      it "should know their repository" do
        Event.repository.should equal @repo
      end

      it "should allow accessing an attribute" do
        event = RDF::URI('http://example.org/events/that-one').as(Event)
        lambda { event.name }.should_not raise_error
      end

      it "should allow calling instance#save!" do
        event = Event.for(RDF::URI.new('http://example.org/events/this-one'))
        lambda { event.save! }.should_not raise_error
      end
    end
  end

  context "classes using a named repository" do

    context "without a set repository" do
      before :each do
        Spira.clear_repositories!
      end

      it "should return nil for a repository which does not exist" do
        Stadium.repository.should be_nil
      end

      it "should raise an error when accessing an attribute" do
        stadium = RDF::URI('http://example.org/stadiums/that-one').as(Stadium)
        lambda { stadium.name }.should raise_error
      end

      it "should raise an error to call instance#save" do
        stadium = Stadium.for(RDF::URI.new('http://example.org/stadiums/this-one'))
        stadium.name = 'test'
        lambda { stadium.save }.should raise_error
      end
    end

    context "with a set repository" do
      before :each do
        Spira.clear_repositories!
        @repo = RDF::Repository.new
        Spira.add_repository(:stadium, @repo)
      end

      it "should know their repository" do
        Stadium.repository.should equal @repo
      end

      it "should allow accessing an attribute" do
        stadium = RDF::URI('http://example.org/stadiums/that-one').as(Stadium)
        lambda { stadium.name }.should_not raise_error
      end

      it "should allow calling instance#save!" do
        stadium = Stadium.for(RDF::URI.new('http://example.org/stadiums/this-one'))
        lambda { stadium.save! }.should_not raise_error
      end
    end
  end
end
