require File.dirname(__FILE__) + "/spec_helper.rb"

describe Spira do

  context "when instantiating" do

    before :all do
      class ::InstantiationTest
        include Spira::Resource

        property :name, :predicate => FOAF.name

      end
      Spira.add_repository(:default, RDF::Repository.new)
    end


    context "when instantiating from a URI" do
      before :each do
        @uri = RDF::URI('http://example.org/example')
      end

      it "should add the 'as' method to RDF::URI" do
        @uri.should respond_to :as
      end

      it "should allow instantiation from a URI using RDF::URI#as" do
        @uri.as(InstantiationTest).should be_a InstantiationTest
      end

      it "should allow instantiation from a resource class using #for" do
        InstantiationTest.for(@uri).should be_a InstantiationTest
      end

      it "should allow instantiation from a URI with attributes given" do
        test = @uri.as(InstantiationTest, :name => "a name")
        test.name.should == "a name"
      end
    end

    context "when instantiating from a BNode" do
      before :each do
        @node = RDF::Node.new
      end

      it "should add the 'as' method to RDF::" do
        @node.should respond_to :as
      end

      it "should allow instantiation from a Node using RDF::Node#as" do
        @node.as(InstantiationTest).should be_a InstantiationTest 
      end

      it "should allow instantiation from a resource class using #for" do
        InstantiationTest.for(@node).should be_a InstantiationTest
      end

      it "should allow instantiation from a Node with attributes given" do
        test = @node.as(InstantiationTest, :name => "a name")
        test.name.should == "a name"
      end
    end

    context "when creating without an identifier" do
      it "should create an instance with a new Node identifier" do
        test = InstantiationTest.new
        test.subject.should be_a RDF::Node
        test.uri.should be_nil
      end
    end

  end
end
