require "spec_helper"

describe Spira do

  context "when instantiating" do

    before :all do
      class ::InstantiationTest < Spira::Base
        property :name, predicate: RDF::Vocab::FOAF.name
      end
    end

    context "when instantiating from a URI" do
      let(:uri) {RDF::URI('http://example.org/example')}
      before(:each) {Spira.repository = RDF::Repository.new}

      it "should add the 'as' method to RDF::URI" do
        expect(uri).to respond_to :as
      end

      it "should allow instantiation from a URI using RDF::URI#as" do
        expect(uri.as(InstantiationTest)).to be_a InstantiationTest
      end

      it "should yield the new instance to a block given to #as" do
        test = uri.as(InstantiationTest) do |test|
          test.name = "test name"
        end
        expect(test.name).to eql "test name"
      end

      it "should allow instantiation from a resource class using #for" do
        expect(InstantiationTest.for(uri)).to be_a InstantiationTest
      end

      it "should yield the new instance to a block given to #for" do
        test = InstantiationTest.for(uri) do |test|
          test.name = "test name"
        end
        expect(test.name).to eql "test name"
      end

      it "should allow instantiation from a URI with attributes given" do
        test = uri.as(InstantiationTest, name: "a name")
        expect(test.name).to eql "a name"
      end

      it "should know if a URI does not exist" do
        expect(InstantiationTest.for(uri)).not_to be_persisted
      end

      it "should know if a URI exists" do
        InstantiationTest.repository << RDF::Statement.new(uri, RDF::Vocab::FOAF.name, 'test')
        expect(InstantiationTest.for(uri)).to be_persisted
      end

      it "should allow the use of #[] as an alias to #for" do
        InstantiationTest.repository << RDF::Statement.new(uri, RDF::Vocab::FOAF.name, 'test')
        expect(InstantiationTest[uri]).to be_persisted
      end
    end

    context "when instantiating from a BNode" do
      let(:node) {RDF::Node.new}
      before {Spira.repository = RDF::Repository.new}

      it "should add the 'as' method to RDF::" do
        expect(node).to respond_to :as
      end

      it "should allow instantiation from a Node using RDF::Node#as" do
        expect(node.as(InstantiationTest)).to be_a InstantiationTest 
      end

      it "should allow instantiation from a resource class using #for" do
        expect(InstantiationTest.for(node)).to be_a InstantiationTest
      end

      it "should allow instantiation from a Node with attributes given" do
        test = node.as(InstantiationTest, name: "a name")
        expect(test.name).to eql "a name"
      end

      it "should allow the use of #[] as an alias to #for" do
        expect(InstantiationTest[node]).to be_a InstantiationTest
      end
    end

    context "when creating without an identifier" do
      before {Spira.repository = RDF::Repository.new}

      it "should create an instance with a new Node identifier" do
        test = InstantiationTest.new
        expect(test.subject).to be_a RDF::Node
        expect(test.uri).to be_nil
      end

      it "should yield the new instance to a block given to #new" do
        test = InstantiationTest.new do |test|
          test.name = "test name"
        end
        expect(test.name).to eql "test name"
      end
    end

  end
end
