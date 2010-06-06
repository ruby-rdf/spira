require File.dirname(__FILE__) + "/spec_helper.rb"

# Fixture to test :default repository loading

describe Spira do

  context ", in regards to a default repository, " do

    before :all do
      @repo = RDF::Repository.new
      class ::Event
        include Spira::Resource
        property :name, :predicate => DC.title
      end
      
      class ::Stadium
        include Spira::Resource
        property :name, :predicate => DC.title
        default_source :stadium
      end
    end

    before :each do
      Spira.clear_repositories!
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
      end
      it "should return nil for a repository which does not exist" do
        Event.repository.should == nil
      end
  
      it "should raise an error when accessing an attribute" do
        event = RDF::URI('http://example.org/events/that-one').as(Event)
        lambda { event.name }.should raise_error Spira::NoRepositoryError
      end
  
      it "should raise an error to call instance#save!" do
        event = Event.for(RDF::URI.new('http://example.org/events/this-one'))
        lambda { event.save! }.should raise_error Spira::NoRepositoryError
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
        Stadium.repository.should == nil
      end
  
      it "should raise an error when accessing an attribute" do
        stadium = RDF::URI('http://example.org/stadiums/that-one').as(Stadium)
        lambda { stadium.name }.should raise_error Spira::NoRepositoryError
      end
  
      it "should raise an error to call instance#save!" do
        stadium = Stadium.for(RDF::URI.new('http://example.org/stadiums/this-one'))
        lambda { stadium.save! }.should raise_error Spira::NoRepositoryError
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
