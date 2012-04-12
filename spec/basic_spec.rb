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

    @person_repository = RDF::Repository.load(fixture('bob.nt'))
    Spira.add_repository(:default, @person_repository)
  end

  before :each do
    @person_repository = RDF::Repository.load(fixture('bob.nt'))
    Spira.add_repository(:default, @person_repository)
  end

  context "The person fixture" do

    it "should know its source" do
      Person.repository.should be_a RDF::Repository
      Person.repository.should equal @person_repository
    end

    context "when instantiating new URIs" do

      it "should offer a for method" do
        Person.should respond_to :for
      end

      it "should be able to create new instances for non-existing resources" do
        lambda { Person.for(RDF::URI.new('http://example.org/newperson')) }.should_not raise_error
      end

      it "should create Person instances" do
        Person.for(RDF::URI.new('http://example.org/newperson')).should be_a Person
      end

      context "with attributes given" do
        before :each do
          @alice = Person.for 'alice', :age => 30, :name => 'Alice'
        end

        it "should have properties if it had them as attributes on creation" do
          @alice.age.should == 30
          @alice.name.should == 'Alice'
        end

        it "should save updated properties" do
          @alice.age = 16
          @alice.age.should == 16
        end

      end
    end

    context "when instantiating existing URIs" do

      it "should return a Person for a non-existent URI" do
        Person.for('nobody').should be_a Person
      end

      it "should return an empty Person for a non-existent URI" do
        person = Person.for('nobody')
        person.age.should be_nil
        person.name.should be_nil
      end

    end

    context "with attributes given" do
      before :each do
        @alice = Person.for 'alice', :age => 30, :name => 'Alice'
        @bob   = Person.for 'bob',   :name => 'Bob Smith II'
      end

      it "should overwrite existing properties with given attributes" do
        @bob.name.should == "Bob Smith II"
      end

      it "should not overwrite existing properties which are not given" do
        @bob.age.should == 15
      end

      it "should allow property updating" do
        @bob.age = 16
        @bob.age.should == 16
      end
    end

    context "A newly-created person" do

      before :each do
        @person = Person.for 'http://example.org/example/people/alice'
      end

      context "in respect to some general methods" do
        it "should #uri" do
          @person.should respond_to :uri
        end

        it "should return a RDF::URI from #uri" do
          @person.uri.should be_a RDF::URI
        end

        it "should return the correct URI from #uri" do
          @person.uri.to_s.should == 'http://example.org/example/people/alice'
        end

        it "should support #to_uri" do
          @person.should respond_to :to_uri
        end

        it "should return the correct URI from #to_uri" do
          @person.to_uri.to_s.should == 'http://example.org/example/people/alice'
        end

        it "should support #to_rdf" do
          @person.should respond_to :to_rdf
        end

        it "should return an RDF::Enumerable for #to_rdf" do
          @person.to_rdf.should be_a RDF::Enumerable
        end
      end

      context "using getters and setters" do
        it "should have a name method" do
          @person.should respond_to :name
        end

        it "should have an age method" do
          @person.should respond_to :age
        end

        it "should return nil for unset properties" do
          @person.name.should == nil
        end

        it "should allow setting a name" do
          lambda { @person.name = "Bob Smith" }.should_not raise_error
        end

        it "should allow getting a name" do
          @person.name = "Bob Smith"
          @person.name.should == "Bob Smith"
        end

        it "should allow setting an age" do
          lambda { @person.age = 15 }.should_not raise_error
        end

        it "should allow getting an age" do
          @person.age = 15
          @person.age.should == 15
        end

        it "should correctly set more than one property" do
          @person.age = 15
          @person.name = "Bob Smith"
          @person.age.should == 15
          @person.name.should == "Bob Smith"
        end
      end
    end

  end
end
