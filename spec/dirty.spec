require File.dirname(__FILE__) + "/spec_helper.rb"


describe Spira do


  before :all do
    class ::DirtyTest
      include Spira::Resource
      base_uri "http://example.org/example/people"
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age,  :type => Integer
    end
  end

  before :each do
    @repo = RDF::Repository.new
    @uri = URI("http://example.org/example/people/alice")
    @repo << RDF::Statement.new(@uri, RDF::RDFS.label, "Alice")
    @repo << RDF::Statement.new(@uri, RDF::FOAF.age, 15)
    Spira.add_repository!(:default, @repo)
  end

  context "when tracking dirty attributes" do

    before :each do
      @test = DirtyTest.for(@uri)
    end

    it "should not mark attributes as dirty when loading" do
      @test.dirty?(:name).should be_false
      @test.dirty?(:age).should be_false
    end

    it "should mark attributes as dirty when changing" do
      @test.name = "Steve"
      @test.dirty?(:name).should be_true
      @test.dirty?(:age).should be_false
    end

    it "should mark attributes as dirty when providing them as arguments" do
      test = DirtyTest.for(@uri, :name => "Steve")
      test.dirty?(:name).should be_true
      test.dirty?(:age).should be_false
    end
  end

end
