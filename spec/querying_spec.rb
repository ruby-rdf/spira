require "spec_helper"

describe Spira do
  let(:options) {{}}
  let(:conditions) {{}}

  before :all do
    class ::LoadTest < Spira::Base
      type RDF::Vocab::FOAF.Document
      configure base_uri: "http://example.com/loads"

      property :name,  predicate: RDF::Vocab::FOAF.name
      property :label, predicate: RDF::RDFS.label
      property :child, predicate: RDF::Vocab::FOAF.currentProject, type: 'LoadTest'
    end
  end

  context "when querying repositories" do
    let(:repo) {RDF::Repository.new}
    let(:uri) {RDF::URI('http://example.org/example')}

    before {Spira.repository = repo}

    shared_examples_for "array that can be paginated" do
      let(:people) {[]}
      before do
        3.times {|i| people << LoadTest.create(name: "person_#{i+1}")}
      end

      it "should yield all records" do
        subject.each {|person| expect(people).to include(person) }
        expect(subject.count).to eql people.size
      end

      context "given :offset option" do
        before { options.merge!(offset: 1) }

        it "should yield records within the given offset" do
          subject.each {|person| expect(person).not_to eql people[0] }
        end
      end

      context "given :limit option" do
        before { options.merge!(limit: 2) }

        it "should yield records within the given limit" do
          subject.each {|person| expect(person).not_to eql people[2] }
        end
      end

      context "given :offset and :limit options" do
        before { options.merge!(limit: 1, offset: 1) }

        it "should yield records withing the resulting range" do
          subject.each do |person|
            expect(person).not_to eql people[0]
            expect(person).not_to eql people[2]
          end
        end
      end
    end

    describe "find_each" do
      subject { LoadTest.find_each(conditions, **options) }

      it { is_expected.to be_a Enumerator }

      it { is_expected.not_to respond_to :to_ary }

      it_should_behave_like "array that can be paginated"
    end

    describe "all" do
      subject { LoadTest.all(options.merge(conditions: conditions)) }

      it { is_expected.to respond_to :to_ary }

      it_should_behave_like "array that can be paginated"
    end

    it "should attempt to query on instantiation" do
      expect(repo).to receive(:query).once.and_return([])
      uri.as(LoadTest)
    end

    it "should attempt query once on property setting" do
      expect(repo).to receive(:query).once.and_return([])
      test = uri.as(LoadTest)
      test.name = "test"
      test.name = "another test"
    end

    it "should not attempt to query on property getting" do
      expect(repo).to receive(:query).once.and_return([])
      test = uri.as(LoadTest)
      test.name
    end

    it "should only query once for all properties" do
      expect(repo).to receive(:query).once.and_return([])
      test = uri.as(LoadTest)
      test.name
      test.label
    end

    it "should support :reload" do
      test = uri.as(LoadTest)
      expect(test).to respond_to :reload
    end

    it "should touch the repository to reload" do
      expect(repo).to receive(:query).twice.and_return([])
      test = uri.as(LoadTest)
      test.reload
    end

    it "should query the repository again after a reload" do
      expect(repo).to receive(:query).twice.and_return([])
      test = uri.as(LoadTest)
      test.name
      test.reload
      test.name
    end

    context "for relations" do
      let(:child_uri) {RDF::URI("http://example.org/example2")}
      let(:parent_statements) {[]}
      let(:child_statements) {[]}
      before :each do
        st = RDF::Statement.new(subject: uri, predicate: RDF::Vocab::FOAF.currentProject, object: child_uri)
        # uri and child_uri now point at each other
        repo << st
        parent_statements << st
        st = RDF::Statement.new(subject: uri, predicate: RDF::Vocab::FOAF.name, object: RDF::Literal.new("a name"))
        repo << st
        parent_statements << st
        st = RDF::Statement.new(subject: uri, predicate: RDF::RDFS.label, object: RDF::Literal.new("a name"))
        repo << st
        parent_statements << st
        st = RDF::Statement.new(subject: uri, predicate: RDF.type, object: RDF::Vocab::FOAF.Document)
        repo << st
        parent_statements << st

        st = RDF::Statement.new(subject: child_uri, predicate: RDF::Vocab::FOAF.currentProject, object: uri)
        repo << st
        child_statements << st
        st = RDF::Statement.new(subject: child_uri, predicate: RDF::Vocab::FOAF.currentProject, object: uri)
        repo << st
        child_statements << st
        st = RDF::Statement.new(subject: child_uri, predicate: RDF.type, object: RDF::Vocab::FOAF.Document)
        repo << st
        child_statements << st
        # We need this copy to return from mocks, as the return value is itself queried inside spira, confusing the count
      end

      it "should not query the repository when loading a parent and not accessing a child" do
        name_statements = parent_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        expect(repo).to receive(:query).with({subject: uri}).once.and_return(name_statements)

        test = uri.as(LoadTest)
        test.name
      end

      it "should query the repository when loading a parent and accessing a field on a child" do
        name_statements = parent_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        expect(repo).to receive(:query).with({subject: uri}).once.and_return(parent_statements)
        expect(repo).to receive(:query).with({subject: child_uri}).once.and_return(name_statements)

        test = uri.as(LoadTest)
        test.child.name
      end

      it "should not re-query to access a child twice" do
        name_statements = parent_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        expect(repo).to receive(:query).with({subject: uri}).once.and_return(parent_statements)
        expect(repo).to receive(:query).with({subject: child_uri}).once.and_return(name_statements)

        test = uri.as(LoadTest)
        2.times { test.child.name }
      end

      it "should re-query to access a child's parent from the child" do
        name_statements = parent_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        expect(repo).to receive(:query).with({subject: uri}).twice.and_return(parent_statements)
        expect(repo).to receive(:query).with({subject: child_uri}).once.and_return(child_statements)

        test = uri.as(LoadTest)
        3.times do
          expect(test.child.child.name).to eql "a name"
        end
      end

      it "should re-query for children after a #reload" do
        parent_name_statements = parent_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        child_name_statements = child_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        expect(repo).to receive(:query).with({subject: uri}).exactly(4).times.and_return(parent_statements)
        expect(repo).to receive(:query).with({subject: child_uri}).twice.and_return(child_statements)

        test = uri.as(LoadTest)
        expect(test.child.child.name).to eql "a name"
        expect(test.child.name).to be_nil
        test.reload
        expect(test.child.child.name).to eql "a name"
        expect(test.child.name).to be_nil
      end

      it "should not re-query to iterate by type twice" do
        pending "no longer applies as the global cache is gone"

        # once to get the list of subjects, once for uri, once for child_uri, 
        # and once for the list of subjects again
        parent_name_statements = parent_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        child_name_statements = child_statements.select {|st| st.predicate == RDF::Vocab::FOAF.name }
        expect(repo).to receive(:query).with(subject: uri, predicate: RDF::Vocab::FOAF.name).twice.and_return(parent_name_statements)
        expect(repo).to receive(:query).with(subject: child_uri, predicate: RDF::Vocab::FOAF.name).twice.and_return(child_name_statements)
        @types = RDF::Repository.new
        @types.insert *repo.statements.select{|s| s.predicate == RDF.type && s.object == RDF::Vocab::FOAF.Document}
        expect(repo).to receive(:query).with(predicate: RDF.type, object: RDF::Vocab::FOAF.Document).twice.and_return(@types.statements)

        # need to map to touch a property on each to make sure they actually
        # get loaded due to lazy evaluation
        2.times do
          expect(LoadTest.each.map { |lt| lt.name }.size).to eql 2
        end
      end

    end
  end
end
