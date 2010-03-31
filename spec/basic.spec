require File.dirname(__FILE__) + "/spec_helper.rb"

# Tests of basic functionality--getting, setting, creating, saving, when no
# relations or anything fancy are involved.


describe Spira do

  context "The person fixture" do

    before :all do
      require 'person'
      require 'rdf/ntriples'
      @person_repository = RDF::Repository.load(fixture('bob.nt'))
    end

    it "should know its source" do
      Person.repository.should be_a RDF::Repository
    end

    it "should have a base path" do
      Person.base_uri.should == "http://example.org/example/people"
    end

    it "should have a find method" do
      Person.should respond_to :find
    end

    context "when creating" do
      it "should be instantiable from a string" do
        lambda {x = Person.create 'bob'}.should_not raise_error
      end

      it "should return nil for a non-existent person" do
        Person.find('nobody').should == nil
      end

      it "should allow setting of attributes at creation" do
        lambda {Person.create 'bob', :age => 15}.should_not raise_error
      end
    end

    context "A newly-created person" do

      before :each do
        @person = Person.create 'bob'
      end

      after :each do
        @person.destroy!
      end

      it "should be destroyable" do
        lambda {@person.destroy!}.should_not raise_error
      end

      it "should be createable with a URI path" do
        @person.uri.should be_a RDF::URI
        @person.uri.to_s.should == "http://example.org/example/people/bob"
      end
      
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

      it "should return strings for the name" do
        @person.name = "Bob Smith"
        @person.name.should be_a String
      end

      it "should return integers for the age" do
        @person.age = 15
        @person.age.should be_a Integer
      end

      it "should save both properties" do
        @person.age = 15
        @person.name = "Bob Smith"
        @person.age.should == 15
        @person.name.should == "Bob Smith"
      end

      # Tests for a bug wherein the original repo to delete was not being updated on save!
      it "should safely delete old repository information on updates" do
        @repo = Person.repository
        @person.age = 16
        @person.save!
        @person.age = 17
        @person.save!
        @repo.query(:predicate => RDF::FOAF.age).size.should == 1
      end


    end

    context "creating with attributes" do
      before :each do
        @alice = Person.create 'alice', :age => 30, :name => 'Alice'
      end

      after :each do
        @alice.destroy!
      end

      it "should have properties if it had them as attributes on creation" do
        @alice.age.should == 30
        @alice.name.should == 'Alice'
      end

      it "should save updated properties" do
        @alice.age = 16
        @alice.age.should == 16
      end
     
      it "should allow saving" do
        @alice.save!
        Person.find('alice').should == @alice
      end

    end

    context "creating without a base URI" do
      it "should raise an exception to create an object without a URI for a class without a base_uri" do
        lambda {employee = Employee.create 'bob'}.should raise_error ArgumentError
      end
    end

    context "getting, setting, and saving" do

      before :all do
        require 'rdf/ntriples'
        @person_repository = RDF::Repository.load(fixture('bob.nt'))
      end

      before :each do
        @person = Person.create 'bob'
        @person.name = "Bob Smith"
        @person.age = 15
      end

      after :each do
        @person.destroy!
      end

      it "should be saveable" do
        lambda { @person.save! }.should_not raise_error
      end

      it "should be findable with a string after saving" do
        @person.save!
        bob = Person.find 'bob'
        bob.should == @person
      end

      it "should be findable via an RDF::URI" do
        @person.save!
        bob = Person.find RDF::URI.new("http://example.org/example/people/bob")
        bob.should == @person
      end

      it "should not find non-existent identifiers after saving one" do
        @person.save!
        Person.find('xyz').should == nil
      end

      it "should save properties" do
        @person.name = "steve"
        @person.save!
        @person.name.should == "steve"
      end

    end
    
    context "as an RDF::Enumerable" do

      before :each do
        @statements = @person_repository
        @person = Person.create 'bob'
        @person.name = "Bob Smith"
        @person.age = 15
        @enumerable = @person
      end

      it_should_behave_like RDF_Enumerable
    end

  end


end



