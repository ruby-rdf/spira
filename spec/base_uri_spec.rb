require "spec_helper"

describe 'Default URIs' do

  before :each do
    Spira.add_repository(:default, ::RDF::Repository)
  end

  context "classes with a base URI" do

    before :all do
      class ::BaseURITest < Spira::Base
        configure :base_uri => "http://example.org/example"
        property :name, :predicate => RDFS.label
      end

      class ::HashBaseURITest < Spira::Base
        configure :base_uri => "http://example.org/example#"
        property :name, :predicate => RDFS.label
      end
    end

    it "have a base URI method" do
      BaseURITest.should respond_to :base_uri
    end

    it "have a correct base URI" do
      BaseURITest.base_uri.should == "http://example.org/example"
    end

    it "provide an id_for method" do
      BaseURITest.should respond_to :id_for
    end

    it "provide a uri based on the base URI for string arguments" do
      BaseURITest.id_for('bob').should == RDF::URI.new('http://example.org/example/bob')
    end

    it "use the string form of an absolute URI as an absolute URI" do
      uri = 'http://example.org/example/bob'
      BaseURITest.id_for(uri).should == RDF::URI.new(uri)
    end

    it "allow any type to be used as a URI fragment, via to_s" do
      uri = 'http://example.org/example/5'
      BaseURITest.id_for(5).should == RDF::URI.new(uri)
    end

    it "allow appending fragment RDF::URIs to base_uris" do
      BaseURITest.for(RDF::URI('test')).subject.to_s.should == 'http://example.org/example/test'
    end

    it "do not raise an exception to project with a relative URI" do
      lambda {x = BaseURITest.for 'bob'}.should_not raise_error
    end

    it "return an absolute, correct RDF::URI from #uri when created with a relative uri" do
      test = BaseURITest.for('bob')
      test.uri.should be_a RDF::URI
      test.uri.to_s.should == "http://example.org/example/bob"
    end

    it "save objects created with a relative URI as absolute URIs" do
      test = BaseURITest.for('bob')
      test.name = 'test'
      test.save!
      saved = BaseURITest.for('bob')
      saved.name.should == 'test'
    end

    it "do not append a / if the base URI ends with a #" do
      HashBaseURITest.id_for('bob').should == RDF::URI.new('http://example.org/example#bob')
    end
  end

  context "classes without a base URI" do
    before :all do
      class ::NoBaseURITest < Spira::Base
        property :name, :predicate => RDFS.label
      end
    end

    it "have a base URI method" do
      NoBaseURITest.should respond_to :base_uri
    end

    it "provide a id_for method" do
      NoBaseURITest.should respond_to :id_for
    end

    it "have a nil base_uri" do
      NoBaseURITest.base_uri.should be_nil
    end

    it "raise an ArgumentError when projected with a relative URI" do
      lambda { x = NoBaseURITest.id_for('bob')}.should raise_error ArgumentError
    end
  end

end
