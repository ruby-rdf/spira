require "spec_helper"


describe Spira do


  before :all do
    class ::DirtyTest < Spira::Base
      property :name,  :predicate => RDFS.label
      property :age,   :predicate => FOAF.age,  :type => Integer
      has_many :items, :predicate => RDFS.seeAlso
    end
  end

  before :each do
    @repo = RDF::Repository.new
    @uri = RDF::URI("http://example.org/example/people/alice")
    @repo << RDF::Statement.new(@uri, RDF::RDFS.label, "Alice")
    @repo << RDF::Statement.new(@uri, RDF::FOAF.age, 15)
    @repo << RDF::Statement.new(@uri, RDF::RDFS.seeAlso, "A Literal")
    @repo << RDF::Statement.new(@uri, RDF::RDFS.seeAlso, "Another Literal")
    Spira.add_repository!(:default, @repo)
  end

  context "when tracking dirty attributes" do

    before :each do
      @test = DirtyTest.for(@uri)
    end

    it "should not mark the projetion as dirty initially" do
      @test.dirty?.should be_false
    end

    context "that are properties" do

      it "should not mark attributes as dirty when loading" do
        @test.dirty?(:name).should be_false
        @test.dirty?(:age).should be_false
      end
  
      it "should mark the projection as dirty if an attribute is dirty" do
        @test.name = "Steve"
        @test.dirty?.should be_true
      end
  
      it "should mark attributes as dirty when changed" do
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

    context "that are lists" do
      it "should not mark attributes as dirty when loading" do
        @test.dirty?(:items).should be_false
      end

      it "should mark the projection as dirty if an attribute is dirty" do
        @test.items = ["Steve"]
        @test.dirty?.should be_true
      end

      it "should mark attributes as dirty when changed" do
        @test.items = ["Steve"]
        @test.dirty?(:items).should be_true
        @test.dirty?(:age).should be_false
      end
  
      it "should mark attributes as dirty when providing them as arguments" do
        test = DirtyTest.for(@uri, :items => ["Steve"])
        test.dirty?(:items).should be_true
        test.dirty?(:age).should be_false
      end

      it "should mark attributes as dirty when updated" do
        @test.items << "Steve"
        @test.dirty?(:items).should be_true
      end

    end
  end

end
