require "spec_helper"

describe Spira::Utils do
  class ::Person < Spira::Base
    configure :base_uri => "http://example.org/example/people"
    property :name, :predicate => RDF::RDFS.label
    property :age,  :predicate => RDF::Vocab::FOAF.age,  :type => Integer
  end

  let(:repository) do
    repo = RDF::Repository.load(fixture('bob.nt'))
    repo << RDF::Statement.new(test_uri, RDF::FOAF.name, 'Not in model')
    repo
  end
  before(:each) {Spira.repository = repository}

  describe "rename!" do
    let(:test_uri) {RDF::URI('http://example.org/example/people/bob')}
    let(:new_uri) {RDF::URI('http://example.org/people/test2')}
    let(:other_uri) {RDF::URI('http://example.org/people/test3')}
    let(:test) {Person.for(test_uri)}
    let(:name) {test.name}
    let(:age) {test.age}
    subject {test}

    it "supports #rename!" do
      is_expected.to respond_to(:rename!)
    end

    it "copies model data to a given subject" do
      subject.rename!(new_uri)
      expect(subject.name).to eql name
      expect(subject.age).to eql age
    end

    it "updates references to the old subject as objects" do
      subject.rename!(new_uri)
      expect(repository).to have_statement RDF::Statement(new_uri, RDF::RDFS.label, name)
      expect(repository).not_to have_statement RDF::Statement(test_uri, RDF::RDFS.label, name)
    end

    it "saves the copy immediately" do
      subject.rename!(new_uri)
      expect(subject.name).to eql name
      expect(subject.age).to eql age
      expect(repository).to have_statement RDF::Statement.new(new_uri, RDF::RDFS.label, name)
      expect(repository).to have_statement RDF::Statement.new(new_uri, RDF::FOAF.age, age)
    end

    it "deletes the old model data" do
      subject.rename!(new_uri)
      expect(repository).not_to have_statement RDF::Statement.new(test_uri, RDF::RDFS.label, name)
      expect(repository).not_to have_statement RDF::Statement.new(test_uri, RDF::FOAF.age, age)
    end

    it "copies non-model data to the given subject" do
      subject.rename!(new_uri)
      expect(repository).to have_statement RDF::Statement.new(new_uri, RDF::FOAF.name, 'Not in model')
    end

    it "deletes all data about the old subject" do
      subject.rename!(new_uri)
      expect(repository.query(subject: test_uri).size).to eql 0
      expect(repository.query(object: test_uri).size).to eql 0
    end
  end
end
