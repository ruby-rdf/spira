require "spec_helper"

# Tests in terms of RDF::Enumerable, and interaction with other enumerables

describe Spira::Base do

  before :all do
    require 'rdf/ntriples'
    Spira.repository = ::RDF::Repository.new

    class ::EnumerableSpec < Spira::Base
      configure :base_uri => "http://example.org/example/people"

      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age,  :type => Integer
    end

    class ::EnumerableWithAssociationsSpec < Spira::Base
      configure :base_uri => "http://example.org/example/people"

      property :name, :predicate => RDFS.label
      has_many :friends, :predicate => FOAF.knows, :type => :EnumerableWithAssociationsSpec
    end
  end

  context "as an RDF::Enumerable" do

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

    context "when just created" do
      before do
        @liza = EnumerableWithAssociationsSpec.new
      end

      it "should have no statements" do
        @liza.statements.size.should be_zero
      end
    end

    context "when has has_many association" do
      before do
        @another_uri = RDF::URI('http://example.org/example/people/charlie')
        @charlie = EnumerableWithAssociationsSpec.for @another_uri
        3.times { @charlie.friends << EnumerableWithAssociationsSpec.new }
      end

      it "should list associated statements individually" do
        @charlie.statements.size.should eql @charlie.friends.size
      end
    end

    context "when running the rdf-spec RDF::Enumerable shared groups" do

      include RDF_Enumerable

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
        pending('Awaiting fix for https://github.com/ruby-rdf/rdf-isomorphic/issues/3') do
          @enumerable_repository.statements.should be_isomorphic_with @enumerable
        end
      end
    end
  end
end
