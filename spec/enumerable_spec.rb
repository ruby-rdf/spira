require "spec_helper"

# Tests in terms of RDF::Enumerable, and interaction with other enumerables

describe Spira::Base do

  before :all do
    Spira.repository = ::RDF::Repository.new

    class ::EnumerableSpec < Spira::Base
      configure :base_uri => "http://example.org/example/people"

      property :name, :predicate => RDF::RDFS.label
      property :age,  :predicate => RDF::Vocab::FOAF.age,  :type => Integer
    end

    class ::EnumerableWithAssociationsSpec < Spira::Base
      configure :base_uri => "http://example.org/example/people"

      property :name, :predicate => RDF::RDFS.label
      has_many :friends, :predicate => RDF::Vocab::FOAF.knows, :type => :EnumerableWithAssociationsSpec
    end
  end

  context "as an RDF::Enumerable" do
    let(:uri) {RDF::URI('http://example.org/example/people/bob')}
    let(:person) do
      p = EnumerableSpec.for uri
      p.name = "Bob Smith"
      p.age = 15
      p
    end
    let(:enumerable_repository) do
      RDF::Repository.new do |repo|
        repo << RDF::Statement.new(uri, RDF::Vocab::FOAF.age, 15)
        repo << RDF::Statement.new(uri, RDF::Vocab::RDFS.label, "Bob Smith")
      end
    end

    context "when just created" do
      subject {EnumerableWithAssociationsSpec.new}
      its(:statements) {is_expected.to be_empty}
    end

    context "when has has_many association" do
      subject { EnumerableWithAssociationsSpec.for RDF::URI('http://example.org/example/people/charlie') }
      before do
        3.times { subject.friends << EnumerableWithAssociationsSpec.new }
      end

      it "should list associated statements individually" do
        expect(subject.statements.size).to eql subject.friends.size
      end
    end

    # @see lib/rdf/spec/enumerable.rb in rdf-spec
    it_behaves_like 'an RDF::Enumerable' do
      before(:each) do
        @rdf_enumerable_iv_statements = enumerable_repository
      end
      let(:enumerable) {  person }
    end

    context "when comparing with other RDF::Enumerables" do
      
      it "should be equal if they are completely the same" do
        expect(person).to eq enumerable_repository
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
        fail
      end

      it "should allow other enumerables to be isomorphic to a resource" do
        expect(enumerable_repository.statements).to be_isomorphic_with person
      end
    end
  end
end
