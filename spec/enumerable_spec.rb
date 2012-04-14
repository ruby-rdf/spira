require "spec_helper"

# Tests in terms of RDF::Enumerable, and interaction with other enumerables

describe Spira::Base do

  context "as an RDF::Enumerable" do

    before :all do
      require 'rdf/ntriples'
      Spira.add_repository(:default, ::RDF::Repository)
      
      class ::EnumerableSpec < Spira::Base
        configure :base_uri => "http://example.org/example/people"
      
        property :name, :predicate => RDFS.label
        property :age,  :predicate => FOAF.age,  :type => Integer
      end
    end

    before :each do
      @uri = RDF::URI('http://example.org/example/people/bob')
      @person = EnumerableSpec.for @uri
      @enumerable_repository = RDF::Repository.new
      @enumerable_repository << RDF::Statement.new(@uri, RDF::FOAF.age, 15)
      @enumerable_repository << RDF::Statement.new(@uri, RDF::RDFS.label, "Bob Smith")
      @statements = @enumerable_repository
      @person.name = "Bob Smith"
      @person.age = 15
      @enumerable = @person
    end

    context "when running the rdf-spec RDF::Enumerable shared groups" do

      it_should_behave_like RDF_Enumerable

    end

    context "when comparing with other RDF::Enumerables" do
      
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
        @enumerable_repository.should be_isomorphic_with @enumerable
      end

    end
  end
end
