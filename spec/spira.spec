$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
$:.unshift(File.join(File.dirname(__FILE__),'fixtures',''))

$:.unshift(File.join(File.dirname(__FILE__),'..','..','rdf-spec','lib'))
$:.unshift(File.join(File.dirname(__FILE__),'..','..','rdf','lib'))
require 'spira'
require 'rdf/spec/enumerable'
require 'rdf/spec'

def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures',filename)
end

describe Spira do

  context "The person fixture" do

    before :all do
      require 'person'
      require 'rdf/ntriples'
      @person_repository = RDF::Repository.load(fixture('bob.nt'))
    end

    it "should be instantiable" do
      x = Person.create 'bob'
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

    it "should return nil for a non-existent person" do
      Person.find('nobody').should == nil
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

      it "should be findable after saving" do
        @person.save!
        bob = Person.find 'bob'
        bob.should == @person
      end

      it "should not find non-existent identifiers after saving one" do
        @person.save!
        Person.find('xyz').should == nil
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



