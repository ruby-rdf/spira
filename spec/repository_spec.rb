require "spec_helper"

# Fixture to test :default repository loading

describe Spira do

  describe ".using_repository" do

    let(:repo) { RDF::Repository.new }
    let(:new_repo) { RDF::Repository.new }

    before :each do
      Spira.repository = repo
    end

    it "should override the original repository for the block" do
      Spira.using_repository(new_repo) do
        Spira.repository.should == new_repo
      end
    end

    it "should restore the original repository after the block" do
      Spira.using_repository(new_repo) { }
      Spira.repository.should == repo
    end

    context "when the block raises an error" do
      it "should restore the original repository" do
        begin
          Spira.using_repository(new_repo) do
            raise Exception.new('Some Error')
          end
        rescue Exception
          Spira.repository.should == repo
        end
      end
    end

  end

  context "when registering the repository" do

    before :all do
      @repo = RDF::Repository.new
      class ::Event < Spira::Base
        property :name, :predicate => DC.title
      end
    end

    before :each do
      Spira.clear_repository!
    end

    context "in a different thread" do
      before :each do
        Spira.repository = @repo
      end

      it "should be another instance" do
        repo = nil

        t = Thread.new {
          repo = Spira.repository
        }
        t.join

        repo.should_not eql(@repo)
      end
    end

    it "should allow updating of the repository" do
      @new_repo = RDF::Repository.new
      Spira.repository = @new_repo
      Event.repository.should equal @new_repo
    end

    it "should allow clearing the repository" do
      Spira.should respond_to :clear_repository!
      Spira.repository = RDF::Repository.new
      Spira.clear_repository!
      Spira.repository.should be_nil
    end

  end

  context "classes using the default repository" do

    context "without a set repository" do
      before { Spira.clear_repository! }

      it "should raise NoRepositoryError if a repository does not exist" do
        expect { Event.repository }.to raise_error Spira::NoRepositoryError
      end
    end

    context "with a set repository" do
      before :each do
        Spira.clear_repository!
        @repo = RDF::Repository.new
        Spira.repository = @repo
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
end
