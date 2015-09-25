require "spec_helper"

# Tests of basic functionality--getting, setting, creating, saving, when no
# relations or anything fancy are involved.

describe Spira do

  before :all do
    require 'rdf/ntriples'

    class ::Person < Spira::Base
      configure :base_uri => "http://example.org/example/people"
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age,  :type => Integer
    end

    class Employee < Spira::Base
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age, :type => Integer
    end
  end

  context "with repository given" do
    let(:person_repository) {RDF::Repository.load(fixture('bob.nt'))}
    before(:each) {Spira.repository = person_repository}

    context "The person fixture" do

      it "should know its source" do
        expect(Person.repository).to be_a RDF::Repository
        expect(Person.repository).to equal person_repository
      end

      context "when instantiating new URIs" do

        it "should offer a for method" do
          expect(Person).to respond_to :for
        end

        it "should be able to create new instances for non-existing resources" do
          expect { Person.for(RDF::URI.new('http://example.org/newperson')) }.not_to raise_error
        end

        it "should create Person instances" do
          expect(Person.for(RDF::URI.new('http://example.org/newperson'))).to be_a Person
        end

        context "with attributes given" do
          let(:alice) {Person.for 'alice', :age => 30, :name => 'Alice'}

          it "should have properties if it had them as attributes on creation" do
            expect(alice.age).to eql 30
            expect(alice.name).to eql 'Alice'
          end

          it "should save updated properties" do
            alice.age = 16
            expect(alice.age).to eql 16
          end

        end
      end

      context "when instantiating existing URIs" do

        it "should return a Person for a non-existent URI" do
          expect(Person.for('nobody')).to be_a Person
        end

        it "should return an empty Person for a non-existent URI" do
          person = Person.for('nobody')
          expect(person.age).to be_nil
          expect(person.name).to be_nil
        end

      end

      context "with attributes given" do
        let(:bob) {Person.for 'bob',   :name => 'Bob Smith II'}

        it "should overwrite existing properties with given attributes" do
          expect(bob.name).to eql "Bob Smith II"
        end

        it "should not overwrite existing properties which are not given" do
          expect(bob.age).to eql 15
        end

        it "should allow property updating" do
          bob.age = 16
          expect(bob.age).to eql 16
        end
      end

      context "A newly-created person" do
        let(:person) {Person.for 'http://example.org/example/people/alice'}

        context "in respect to some general methods" do
          it "should #uri" do
            expect(person).to respond_to :uri
          end

          it "should return a RDF::URI from #uri" do
            expect(person.uri).to be_a RDF::URI
          end

          it "should return the correct URI from #uri" do
            expect(person.uri.to_s).to eql 'http://example.org/example/people/alice'
          end

          it "should support #to_uri" do
            expect(person).to respond_to :to_uri
          end

          it "should return the correct URI from #to_uri" do
            expect(person.to_uri.to_s).to eql 'http://example.org/example/people/alice'
          end

          it "should support #to_rdf" do
            expect(person).to respond_to :to_rdf
          end

          it "should return an RDF::Enumerable for #to_rdf" do
            expect(person.to_rdf).to be_a RDF::Enumerable
          end
        end

        context "using getters and setters" do
          it "should have a name method" do
            expect(person).to respond_to :name
          end

          it "should have an age method" do
            expect(person).to respond_to :age
          end

          it "should return nil for unset properties" do
            expect(person.name).to eql nil
          end

          it "should allow setting a name" do
            expect { person.name = "Bob Smith" }.not_to raise_error
          end

          it "should allow getting a name" do
            person.name = "Bob Smith"
            expect(person.name).to eql "Bob Smith"
          end

          it "should allow setting an age" do
            expect { person.age = 15 }.not_to raise_error
          end

          it "should allow getting an age" do
            person.age = 15
            expect(person.age).to eql 15
          end

          it "should correctly set more than one property" do
            person.age = 15
            person.name = "Bob Smith"
            expect(person.age).to eql 15
            expect(person.name).to eql "Bob Smith"
          end
        end
      end
    end
  end

  context "without a repository" do
    before { Spira.clear_repository! }

    let(:bob) { RDF::URI("http://example.org/example/people/bob").as(Person) }

    context "when saved" do
      it "should raise NoRepositoryError exception" do
        expect { bob.save }.to raise_exception Spira::NoRepositoryError
      end
    end
  end
end
