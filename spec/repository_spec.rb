require "spec_helper"

# Fixture to test :default repository loading

describe Spira do
  let(:repo) { RDF::Repository.new }
  before {Spira.repository = repo}

  describe ".using_repository" do

    let(:new_repo) { RDF::Repository.new }

    it "should override the original repository for the block" do
      Spira.using_repository(new_repo) do
        expect(Spira.repository).to eql new_repo
      end
    end

    it "should restore the original repository after the block" do
      Spira.using_repository(new_repo) { }
      expect(Spira.repository).to eql repo
    end

    context "when the block raises an error" do
      it "should restore the original repository" do
        begin
          Spira.using_repository(new_repo) do
            raise Exception.new('Some Error')
          end
        rescue Exception
          expect(Spira.repository).to eql repo
        end
      end
    end

  end

  context "when registering the repository" do

    class ::Event < Spira::Base
      property :name, :predicate => RDF::Vocab::DC.title
    end

    before :each do
      Spira.clear_repository!
    end

    context "in a different thread" do
      before {Spira.repository = repo}

      it "should be another instance" do
        repo2 = nil

        t = Thread.new {
          repo2 = Spira.repository
        }
        t.join

        expect(repo2).not_to eql(repo)
      end
    end

    it "should allow updating of the repository" do
      new_repo = RDF::Repository.new
      Spira.repository = new_repo
      expect(Event.repository).to equal new_repo
    end

    it "should allow clearing the repository" do
      expect(Spira).to respond_to :clear_repository!
      Spira.repository = RDF::Repository.new
      Spira.clear_repository!
      expect(Spira.repository).to be_nil
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
        Spira.repository = repo
      end

      it "should know their repository" do
        expect(Event.repository).to equal repo
      end

      it "should allow accessing an attribute" do
        event = RDF::URI('http://example.org/events/that-one').as(Event)
        expect { event.name }.not_to raise_error
      end

      it "should allow calling instance#save!" do
        event = Event.for(RDF::URI.new('http://example.org/events/this-one'))
        expect { event.save! }.not_to raise_error
      end
    end
  end
end
