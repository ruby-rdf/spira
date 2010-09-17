require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

describe Spira do

  before :all do
    class ::LoadTest
      include Spira::Resource
      type FOAF.load_type
      property :name,       :predicate => FOAF.name
      property :label,      :predicate => RDFS.label
      property :child, :predicate => FOAF.load_test, :type => 'LoadTest'
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
        @child_uri = RDF::URI("http://example.org/example2")
        @repo << RDF::Statement.new(:subject => @uri, :predicate => RDF::FOAF.load_test, :object => @child_uri)
        @repo << RDF::Statement.new(:subject => @uri, :predicate => RDF::FOAF.name, :object => RDF::Literal.new("a name"))
        @repo << RDF::Statement.new(:subject => @uri, :predicate => RDF::RDFS.label, :object => RDF::Literal.new("a name"))
        # @uri and @child_uri now point at each other
        @repo << RDF::Statement.new(:subject => @child_uri, :predicate => RDF::FOAF.load_test, :object => @uri)
        @repo << RDF::Statement.new(:subject => @child_uri, :predicate => RDF::FOAF.load_test, :object => @uri)
        # Set up types for iteration
        @repo << RDF::Statement.new(:subject => @uri, :predicate => RDF.type, :object => RDF::FOAF.load_type)
        @repo << RDF::Statement.new(:subject => @child_uri, :predicate => RDF.type, :object => RDF::FOAF.load_type)
        # We need this copy to return from mocks, as the return value is itself queried inside spira, 
        # confusing the count 
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
        child = test.child.name
      end

      it "should not re-query to access a child twice" do
        @repo.should_receive(:query).twice.and_return(@statements, [])
        test = @uri.as(LoadTest)
        child = test.child.name
        child = test.child.name
      end

      it "should not re-query to access a child's parent from the child" do
        @repo.should_receive(:query).twice.and_return(@statements)
        test = @uri.as(LoadTest)
        test.child.child.name.should == "a name"
      end

      it "should not re-query to iterate by type twice" do
        # once to get the list of subjects, once for @uri, once for @child_uri, 
        # and once for the list of subjects again
        @repo.should_receive(:query).exactly(4).times.and_return(@statements)
        # need to map to touch a property on each to make sure they actually
        # get loaded due to lazy evaluation
        LoadTest.each.map { |lt| lt.name }.size.should == 2
        LoadTest.each.map { |lt| lt.name }.size.should == 2
      end

      it "should not touch the repository to reload" do
        @repo.should_not_receive(:query)
        LoadTest.reload
      end

      it "should query the repository again after a reload" do
        # once for list of subjects, twice for items, once for list of subjects, twice for items
        @repo.should_receive(:query).exactly(6).times.and_return(@statements)
        LoadTest.each.map { |lt| lt.name }.size.should == 2
        LoadTest.reload
        LoadTest.each.map { |lt| lt.name }.size.should == 2
      end
    end
  end

end
