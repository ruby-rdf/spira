require File.dirname(__FILE__) + "/spec_helper.rb"

# Tests of basic functionality--getting, setting, creating, saving, when no
# relations or anything fancy are involved.

describe Spira do

  before :all do
    class ::Person
      include Spira::Resource
      base_uri "http://example.org/example/people"
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age,  :type => Integer
    end
    
    class Employee
      include Spira::Resource
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age, :type => Integer
    end

    require 'rdf/ntriples'
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

    context "saving" do

      before :each do
        @person = Person.for 'alice'
        @person.name = "Alice Smith"
        @person.age = 15
      end

      it "should be saveable" do
        lambda { @person.save! }.should_not raise_error
      end

      it "should be findable after saving" do
        @person.save!
        alice = Person.for RDF::URI.new("http://example.org/example/people/alice")
        alice.should == @person
      end

      it "should not find non-existent identifiers after saving an existing one" do
        @person.save!
        Person.for('xyz').should be_a Person
        Person.for('xyz').name.should be_nil
        Person.for('xyz').age.should be_nil
      end

      it "should save properties" do
        @person.name = "steve"
        @person.save!
        @person.name.should == "steve"
        alice = Person.for RDF::URI.new("http://example.org/example/people/alice")
        alice.name.should == "steve"
      end

      it "should add saved statements to the repository" do
        uri = @person.uri
        @person.save!
        @person_repository.should have_statement RDF::Statement.new(uri, RDF::RDFS.label, 'Alice Smith')
        @person_repository.should have_statement RDF::Statement.new(uri, RDF::FOAF.age, RDF::Literal.new(15))
        @person_repository.query(:subject => uri).count.should == 2
      end

      # Tests for a bug wherein the originally loaded attributes were being
      # deleted on save!, not the current ones
      it "should safely delete old repository information on updates" do
        @repo = Person.repository
        uri = @person.uri
        @person.age = 16
        @person.save!
        @person.age = 17
        @person.save!
        @repo.query(:subject => uri, :predicate => RDF::FOAF.age).size.should == 1
        @repo.first_value(:subject => uri, :predicate => RDF::FOAF.age).should == "17"
      end

      it "should delete original information when saving" do
        bob = Person.for 'incorrect'
        bob.age.should == 15 # in the fixture
        bob.age = 17
        bob.save!
        Person.repository.query(:subject => bob.uri, :predicate => RDF::FOAF.age).size.should == 1
        Person.repository.first_value(:subject => bob.uri, :predicate => RDF::FOAF.age).should == "17"
      end
    end

    context "destroying" do
      before :each do
        @bob = Person.for 'bob'
      end

      it "should respond to destroy!" do
        @bob.should respond_to :destroy!
      end
       
      it "should destroy the resource with #destroy!" do
        @bob.destroy!
        @bob.name.should be_nil
        @bob.age.should be_nil
      end

      it "should remove the resource's statements from the repository" do
        uri = @bob.uri
        @bob.destroy!
        @person_repository.query(:subject => uri).to_a.should == []
      end
    end
    
  end
end
