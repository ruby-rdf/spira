require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

describe Spira do

  context "when instantiating" do

    before :all do
      class ::InstantiationTest < Spira::Base
        property :name, :predicate => FOAF.name
      end
    end

    context "when instantiating from a URI" do
      before :each do
        @uri = RDF::URI('http://example.org/example')
        Spira.add_repository(:default, RDF::Repository.new)
        @repo = Spira.repository(:default)
      end

      it "should add the 'as' method to RDF::URI" do
        @uri.should respond_to :as
      end

      it "should allow instantiation from a URI using RDF::URI#as" do
        @uri.as(InstantiationTest).should be_a InstantiationTest
      end

      it "should yield the new instance to a block given to #as" do
        test = @uri.as(InstantiationTest) do |test|
          test.name = "test name"
        end
        test.name.should == "test name"
      end

      it "should allow instantiation from a resource class using #for" do
        InstantiationTest.for(@uri).should be_a InstantiationTest
      end

      it "should yield the new instance to a block given to #for" do
        test = InstantiationTest.for(@uri) do |test|
          test.name = "test name"
        end
        test.name.should == "test name"
      end

      it "should allow instantiation from a URI with attributes given" do
        test = @uri.as(InstantiationTest, :name => "a name")
        test.name.should == "a name"
      end

      it "should know if a URI does not exist" do
        InstantiationTest.for(@uri).exists?.should be_false
        InstantiationTest.for(@uri).exist?.should be_false
      end

      it "should know if a URI exists" do
        InstantiationTest.repository << RDF::Statement.new(@uri, RDF::FOAF.name, 'test')
        InstantiationTest.for(@uri).exists?.should be_true
        InstantiationTest.for(@uri).exist?.should be_true
      end

      it "should allow the use of #[] as an alias to #for" do
        InstantiationTest.repository << RDF::Statement.new(@uri, RDF::FOAF.name, 'test')
        InstantiationTest[@uri].exists?.should be_true
      end
    end

    context "when instantiating from a BNode" do
      before :each do
        @node = RDF::Node.new
        Spira.add_repository(:default, RDF::Repository.new)
        @repo = Spira.repository(:default)
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

      it "should allow the use of #[] as an alias to #for" do
        InstantiationTest[@node].should be_a InstantiationTest
      end
    end

    context "when creating without an identifier" do
      before :each do
        Spira.add_repository(:default, RDF::Repository.new)
        @repo = Spira.repository(:default)
      end

      it "should create an instance with a new Node identifier" do
        test = InstantiationTest.new
        test.subject.should be_a RDF::Node
        test.uri.should be_nil
      end

      it "should yield the new instance to a block given to #new" do
        test = InstantiationTest.new do |test|
          test.name = "test name"
        end
        test.name.should == "test name"
      end
    end

  end
end
