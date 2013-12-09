require "spec_helper"

# Behaviors relating to BNodes vs URIs

describe 'Spira resources' do

  before :all do
    class ::NodeTest < Spira::Base
      property :name, :predicate => FOAF.name
    end
  end

  before :each do
    Spira.clear_repository!
    Spira.repository = RDF::Repository.new
  end

  context "when instatiated from URIs" do
    before :each do
      @uri = RDF::URI('http://example.org/bob')
      @test = @uri.as(NodeTest)
    end

    it "should respond to :to_uri" do
      @test.should respond_to :to_uri
    end

    it "should not respond to :to_node" do
      @test.should_not respond_to :to_node
    end

    it "should not be a node" do
      @test.node?.should be_false
    end

    it "should return the subject URI for :to_uri" do
      @test.to_uri.should == @uri
    end

    it "should raise a NoMethodError for :to_node" do
      lambda { @test.to_node }.should raise_error NoMethodError
    end
  end

  context "when instantiated from Nodes" do
    before :each do
      @node = RDF::Node.new
      @test = @node.as(NodeTest)
    end
    
    it "should not respond to :to_uri" do
      @test.should_not respond_to :to_uri
    end

    it "should respond to :to_node" do
      @test.should respond_to :to_node
    end

    it "should not be a node" do
      @test.node?.should be_true
    end

    it "should return the subject URI for :to_node" do
      @test.to_node.should == @node
    end

    it "should raise a NoMethodError for :to_uri" do
      lambda { @test.to_uri }.should raise_error NoMethodError
    end
  end
end
