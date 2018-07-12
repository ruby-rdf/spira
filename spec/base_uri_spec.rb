require "spec_helper"

describe 'Default URIs' do

  before(:each) {Spira.repository = RDF::Repository.new}

  context "classes with a base URI" do

    before :all do
      class ::BaseURITest < Spira::Base
        configure :base_uri => "http://example.org/example"
        property :name, :predicate => RDF::RDFS.label
      end

      class ::HashBaseURITest < Spira::Base
        configure :base_uri => "http://example.org/example#"
        property :name, :predicate => RDF::RDFS.label
      end
    end

    it "have a base URI method" do
      expect(BaseURITest).to respond_to :base_uri
    end

    it "have a correct base URI" do
      expect(BaseURITest.base_uri).to eql "http://example.org/example"
    end

    it "provide an id_for method" do
      expect(BaseURITest).to respond_to :id_for
    end

    it "provide a uri based on the base URI for string arguments" do
      expect(BaseURITest.id_for('bob')).to eql RDF::URI.new('http://example.org/example/bob')
    end

    it "use the string form of an absolute URI as an absolute URI" do
      uri = 'http://example.org/example/bob'
      expect(BaseURITest.id_for(uri)).to eql RDF::URI.new(uri)
    end

    it "allow any type to be used as a URI fragment, via to_s" do
      uri = 'http://example.org/example/5'
      expect(BaseURITest.id_for(5)).to eql RDF::URI.new(uri)
    end

    it "allow appending fragment RDF::URIs to base_uris" do
      expect(BaseURITest.for(RDF::URI('test')).subject.to_s).to eql 'http://example.org/example/test'
    end

    it "do not raise an exception to project with a relative URI" do
      expect {x = BaseURITest.for 'bob'}.not_to raise_error
    end

    it "return an absolute, correct RDF::URI from #uri when created with a relative uri" do
      test = BaseURITest.for('bob')
      expect(test.uri).to be_a RDF::URI
      expect(test.uri.to_s).to eql "http://example.org/example/bob"
    end

    it "save objects created with a relative URI as absolute URIs" do
      test = BaseURITest.for('bob')
      test.name = 'test'
      test.save!
      saved = BaseURITest.for('bob')
      expect(saved.name).to eql 'test'
    end

    it "do not append a / if the base URI ends with a #" do
      expect(HashBaseURITest.id_for('bob')).to eql RDF::URI.new('http://example.org/example#bob')
    end
  end

  context "classes without a base URI" do
    before :all do
      class ::NoBaseURITest < Spira::Base
        property :name, :predicate => RDF::RDFS.label
      end
    end

    it "have a base URI method" do
      expect(NoBaseURITest).to respond_to :base_uri
    end

    it "provide a id_for method" do
      expect(NoBaseURITest).to respond_to :id_for
    end

    it "have a nil base_uri" do
      expect(NoBaseURITest.base_uri).to be_nil
    end

    it "raise an ArgumentError when projected with a relative URI" do
      expect { x = NoBaseURITest.id_for('bob')}.to raise_error ArgumentError
    end
  end

end
