require "spec_helper"

describe Spira do

  before :all do
    class ::LoadTest < Spira::Base
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
        @parent_statements = []
        @child_statements = []

        st = RDF::Statement.new(:subject => @uri, :predicate => RDF::FOAF.load_test, :object => @child_uri)
        # @uri and @child_uri now point at each other
        @repo << st
        @parent_statements << st
        st = RDF::Statement.new(:subject => @uri, :predicate => RDF::FOAF.name, :object => RDF::Literal.new("a name"))
        @repo << st
        @parent_statements << st
        st = RDF::Statement.new(:subject => @uri, :predicate => RDF::RDFS.label, :object => RDF::Literal.new("a name"))
        @repo << st
        @parent_statements << st
        st = RDF::Statement.new(:subject => @uri, :predicate => RDF.type, :object => RDF::FOAF.load_type)
        @repo << st
        @parent_statements << st

        st = RDF::Statement.new(:subject => @child_uri, :predicate => RDF::FOAF.load_test, :object => @uri)
        @repo << st
        @child_statements << st
        st = RDF::Statement.new(:subject => @child_uri, :predicate => RDF::FOAF.load_test, :object => @uri)
        @repo << st
        @child_statements << st
        st = RDF::Statement.new(:subject => @child_uri, :predicate => RDF.type, :object => RDF::FOAF.load_type)
        @repo << st
        @child_statements << st
        # We need this copy to return from mocks, as the return value is itself queried inside spira, confusing the count
      end

      it "should not query the repository when loading a parent and not accessing a child" do
        @repo.should_receive(:query).with(:subject => @uri).once.and_return(@parent_statements)

        test = @uri.as(LoadTest)
        test.name
      end

      it "should query the repository when loading a parent and accessing a field on a child" do
        @repo.should_receive(:query).with(:subject => @uri).once.and_return(@parent_statements)
        @repo.should_receive(:query).with(:subject => @child_uri).once.and_return(@child_statements)

        test = @uri.as(LoadTest)
        test.child.name
      end

      it "should not re-query to access a child twice" do
        @repo.should_receive(:query).with(:subject => @uri).once.and_return(@parent_statements)
        @repo.should_receive(:query).with(:subject => @child_uri).once.and_return(@child_statements)

        test = @uri.as(LoadTest)
        2.times { test.child.name }
      end

      it "should not re-query to access a child's parent from the child" do
        @repo.should_receive(:query).with(:subject => @uri).once.and_return(@parent_statements)
        @repo.should_receive(:query).with(:subject => @child_uri).once.and_return(@child_statements)

        test = @uri.as(LoadTest)
        3.times do
          test.child.child.name.should == "a name"
        end
      end

      it "should re-query for children after a #reload" do
        @repo.should_receive(:query).with(:subject => @uri).twice.and_return(@parent_statements)
        @repo.should_receive(:query).with(:subject => @child_uri).twice.and_return(@child_statements)

        test = @uri.as(LoadTest)
        test.child.child.name.should == "a name"
        test.child.name.should be_nil
        test.reload
        test.child.child.name.should == "a name"
        test.child.name.should be_nil
      end

      it "should not re-query to iterate by type twice" do
        # once to get the list of subjects, once for @uri, once for @child_uri, 
        # and once for the list of subjects again
        @repo.should_receive(:query).with(:subject => @uri).once.and_return(@parent_statements)
        @repo.should_receive(:query).with(:subject => @child_uri).once.and_return(@child_statements)
        @types = RDF::Repository.new
        @types.insert *@repo.statements.select{|s| s.predicate == RDF.type && s.object == RDF::FOAF.load_type}
        @repo.should_receive(:query).with(:predicate => RDF.type, :object => RDF::FOAF.load_type).twice.and_return(@types.statements)

        # need to map to touch a property on each to make sure they actually
        # get loaded due to lazy evaluation
        2.times do
          LoadTest.each.map { |lt| lt.name }.size.should == 2
        end
      end

      it "should not touch the repository to reload" do
        @repo.should_not_receive(:query)

        LoadTest.reload
      end

      it "should query the repository again after a reload" do
        # once for list of subjects, twice for items, once for list of subjects, twice for items
        # @repo.should_receive(:query).with(:subject => @uri).exactly(6).times.and_return(@parent_statements)
        @repo.should_receive(:query).with(:subject => @uri).twice.and_return(@parent_statements)
        @repo.should_receive(:query).with(:subject => @child_uri).twice.and_return(@child_statements)
        @types = RDF::Repository.new
        @types.insert *@repo.statements.select{|s| s.predicate == RDF.type && s.object == RDF::FOAF.load_type}
        @repo.should_receive(:query).with(:predicate => RDF.type, :object => RDF::FOAF.load_type).twice.and_return(@types.statements)

        LoadTest.each.map { |lt| lt.name }.size.should == 2
        LoadTest.reload
        LoadTest.each.map { |lt| lt.name }.size.should == 2
      end
    end
  end
end
