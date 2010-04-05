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
      @enumerable_repository = RDF::Repository.load(fixture('bob.nt'))
    end

    context "when running the rdf-spec RDF::Enumerable shared groups" do

      before :each do
        @statements = @enumerable_repository
        @person = Person.create 'bob'
        @person.name = "Bob Smith"
        @person.age = 15
        @enumerable = @person
      end

      it_should_behave_like RDF_Enumerable

    end

  end
end
