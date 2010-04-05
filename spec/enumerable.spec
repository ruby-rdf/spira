require File.dirname(__FILE__) + "/spec_helper.rb"

Spira.add_repository(:enumerable, ::RDF::Repository)

class EnumerableSpec
  include Spira::Resource

  default_source :enumerable

  # the default base path to find Persons
  base_uri "http://example.org/example/people"

  property :name, :predicate => RDFS.label
  property :age,  :predicate => FOAF.age,  :type => Integer
end


# Tests in terms of RDF::Enumerable, and interaction with other enumerables

describe Spira::Resource do

  context "as an RDF::Enumerable" do

    before :all do
      require 'rdf/ntriples'
    end

    before :each do
      @enumerable_repository = RDF::Repository.load(fixture('bob.nt'))
      @statements = @enumerable_repository
      @person = Person.create 'bob'
      @person.name = "Bob Smith"
      @person.age = 15
      @enumerable = @person
    end

    context "when running the rdf-spec RDF::Enumerable shared groups" do

      before :each do
      end

      it_should_behave_like RDF_Enumerable

    end

    context "when comparing with other RDF::Enumerables" do

      before :each do
      end

      it "should be equal if they are completely the same" do
        @enumerable.should == @enumerable_repository
      end

      # This one is a tough call.  Are two resources really equal if one is a
      # subset of the other?  No.  But Spira is supposed to let you access
      # existing data, and that means you might have data which has properties
      # a model class doesn't know about.
      #
      # Spira will default, then, to calling itself equal to an enumerable
      # which has the same uri and all the same properties, and then some.
      it "should be equal if the resource is a subgraph of the repository" do
        pending "Awaiting subgraph implementation in rdf_isomorphic"
      end

      it "should allow other enumerables to be isomorphic to a resource" do
        #pending "what to do here?  monkey-patching rdf::enumerable wont work for implementations which override that anyway."
        @enumerable_repository.should be_isomorphic_with @enumerable
      end

      it "should allow other enumerables to be == to a resource" do
        pending "what to do here?  monkey-patching rdf::enumerable wont work for implementations which override that anyway."
        @enumerable_repository.should == @enumerable
      end

    end
  end
end
