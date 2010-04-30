require File.dirname(__FILE__) + "/spec_helper.rb"

describe Spira do

  context "when loading" do

    before :all do
      class LoadTest
        include Spira::Resource

        property :name,  :predicate => FOAF.name
        property :label, :predicate => RDFS.label
      end
    end

    before :each do
      @repo = RDF::Repository.new
      Spira.add_repository(:default, @repo)
      @uri = RDF::URI('http://example.org/example')
    end

    it "should not attempt to load from the repository on instantiation" do
      @repo.should_not_receive(:query)
      test = @uri.as(LoadTest)
    end

    it "should attempt to load from the repository on property access" do
      @repo.should_receive(:query).once
      test = @uri.as(LoadTest)
      name = test.name
      label = test.label
    end

    it "should support :reload" do
      test = @uri.as(LoadTest)
      test.should respond_to :reload
    end

    it "should not touch the repository to reload" do
      @repo.should_not_receive(:query)
      test = @uri.as(LoadTest)
      test.reload
    end
  end

end
