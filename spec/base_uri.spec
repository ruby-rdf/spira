require File.dirname(__FILE__) + "/spec_helper.rb"

describe 'Default URIs' do

  before :all do
    class BaseURITest
      include Spira::Resource
      base_uri "http://example.org/example"
      property :name, :predicate => RDFS.label
    end
    
    class NoBaseURITest
      include Spira::Resource
      property :name, :predicate => RDFS.label
    end

  end

  before :each do
    Spira.add_repository(:default, ::RDF::Repository)
  end

  context "classes with a base URI" do

    it "should provide a uri_for method" do
      BaseURITest.should respond_to :uri_for
    end

    it "should provide a uri based on the base URI for string arguments" do
      BaseURITest.uri_for('bob').should == RDF::URI.new('http://example.org/example/bob')
    end

    it "should correctly figure out that a string of an absolute URI is an absolute URI" do
      uri = 'http://example.org/example/bob'
      BaseURITest.uri_for(uri).should == RDF::URI.new(uri)
    end

    it "should not raise an exception to create an object without a URI for a class without a base_uri" do
      lambda {x = BaseURITest.create 'bob'}.should_not raise_error 
    end

    it "should be createable with a URI path" do
      baseuri = BaseURITest.create('bob')
      baseuri.uri.should be_a RDF::URI
      baseuri.uri.to_s.should == "http://example.org/example/bob"
    end

    it "should save objects created with a relative URI using an absolute URI" do
      baseuri = BaseURITest.create('bob')
      baseuri.name = 'test'
      baseuri.save!
      saved = BaseURITest.find('bob')
      saved.name.should == 'test'
    end
  end

  context "classes without a base URI" do
    it "should provide a uri_for method" do
      NoBaseURITest.should respond_to :uri_for
    end

    it "should raise an ArgumentError when asking for a relative uri" do
      lambda { x = NoBaseURITest.uri_for('bob')}.should raise_error ArgumentError
    end

    it "should raise an ArgumentError to create an object without a URI for a class without a base_uri" do
      lambda { x = NoBaseURITest.create 'bob'}.should raise_error ArgumentError
    end
  end

end
