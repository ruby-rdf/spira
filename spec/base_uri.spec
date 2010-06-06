require File.dirname(__FILE__) + "/spec_helper.rb"

describe 'Default URIs' do

  before :all do
    class ::BaseURITest
      include Spira::Resource
      base_uri "http://example.org/example"
      property :name, :predicate => RDFS.label
    end

    class ::HashBaseURITest
      include Spira::Resource
      base_uri "http://example.org/example#"
      property :name, :predicate => RDFS.label
    end

    class ::NoBaseURITest
      include Spira::Resource
      property :name, :predicate => RDFS.label
    end

  end

  before :each do
    Spira.add_repository(:default, ::RDF::Repository)
  end

  context "all classes" do
    it "should have a base URI method" do
      BaseURITest.should respond_to :base_uri
      NoBaseURITest.should respond_to :base_uri
    end

  end

  context "classes with a base URI" do

    it "should have a correct base URI" do
      BaseURITest.base_uri.should == "http://example.org/example"
    end

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

    it "should allow any type to be used as a URI fragment, via to_s" do 
      uri = 'http://example.org/example/5'
      BaseURITest.uri_for(5).should == RDF::URI.new(uri)
    end

    it "should not raise an exception to create an object without a URI for a class without a base_uri" do
      lambda {x = BaseURITest.for 'bob'}.should_not raise_error 
    end

    it "should be createable with a relative URI" do
      lambda { baseuri = BaseURITest.for('bob') }.should_not raise_error
    end

    it "should return an absolute, correct RDF::URI from #uri when created with a relative uri" do
      baseuri = BaseURITest.for('bob')
      baseuri.uri.should be_a RDF::URI
      baseuri.uri.to_s.should == "http://example.org/example/bob"
    end

    it "should save objects created with a relative URI using an absolute URI" do
      baseuri = BaseURITest.for('bob')
      baseuri.name = 'test'
      baseuri.save!
      saved = BaseURITest.for('bob')
      saved.name.should == 'test'
    end

    it "should not append a / if the base URI ends with a #" do
      HashBaseURITest.uri_for('bob').should == RDF::URI.new('http://example.org/example#bob')
    end
  end

  context "classes without a base URI" do
    it "should provide a uri_for method" do
      NoBaseURITest.should respond_to :uri_for
    end

    it "should have a nil base_uri" do
      NoBaseURITest.base_uri.should be_nil
    end

    it "should raise an ArgumentError when asking for a relative uri" do
      lambda { x = NoBaseURITest.uri_for('bob')}.should raise_error ArgumentError
    end

    it "should raise an ArgumentError to create an object without a URI for a class without a base_uri" do
      lambda { x = NoBaseURITest.for 'bob'}.should raise_error ArgumentError
    end
  end

end
