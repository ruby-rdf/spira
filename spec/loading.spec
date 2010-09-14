require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

describe Spira do

  before :all do
    class ::LoadTest
      include Spira::Resource

      property :name,       :predicate => FOAF.name
      property :label,      :predicate => RDFS.label
      property :load_child, :predicate => FOAF.load_test, :type => 'LoadTest'
    end
  end

  context "when querying repositories" do

    before :each do
      @repo = RDF::Repository.new
      Spira.add_repository(:default, @repo)
      @uri = RDF::URI('http://example.org/example')
    end

    it "should not attempt to query on instantiation" do
      @repo.should_not_receive(:query)
      test = @uri.as(LoadTest)
    end

    it "should not attempt query on property setting" do
      @repo.should_not_receive(:query)
      test = @uri.as(LoadTest)
      test.name = "test"
    end

    it "should attempt to query on property getting" do
      @repo.should_receive(:query).once.and_return([])
      test = @uri.as(LoadTest)
      name = test.name
    end

    it "should only query once for all properties" do
      @repo.should_receive(:query).once.and_return([])
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

    it "should query the repository again after a reload" do
      @repo.should_receive(:query).twice.and_return([])
      test = @uri.as(LoadTest)
      name = test.name
      test.reload
      name = test.name
    end

    context "for relations" do
      before :each do
        @repo << RDF::Statement.new(:subject => @uri, :predicate => RDF::FOAF.load_test, :object => RDF::URI("http://example.org/example2"))
        @repo << RDF::Statement.new(:subject => @uri, :predicate => RDF::FOAF.name, :object => RDF::Literal.new("a name"))
        @repo << RDF::Statement.new(:subject => @uri, :predicate => RDF::RDFS.label, :object => RDF::Literal.new("a name"))
        # We need this copy to return from mocks, as the return value is itself queried inside spira
        @statements = RDF::Repository.new
        @statements.insert(*@repo)
      end

      it "should not query the repository when loading a parent and not accessing a child" do
        @repo.should_receive(:query).once.and_return(@statements)
        test = @uri.as(LoadTest)
        name = test.name
      end

      it "should query the repository when loading a parent and accessing a field on a child" do
        @repo.should_receive(:query).twice.and_return(@statements, [])
        test = @uri.as(LoadTest)
        child = test.load_child.name
      end
    end
  end

end
