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
    Spira.repository = @repo
  end

  context "when tracking dirty attributes" do

    before :each do
      @test = DirtyTest.for(@uri)
    end

    it "should not mark the projetion as dirty initially" do
      @test.should_not be_changed
    end

    context "that are properties" do

      it "should not mark attributes as dirty when loading" do
        @test.changed_attributes.should_not include("name")
        @test.changed_attributes.should_not include("age")
      end
  
      it "should mark the projection as dirty if an attribute is dirty" do
        @test.name = "Steve"
        @test.should be_changed
      end
  
      it "should mark attributes as dirty when changed" do
        @test.name = "Steve"
        @test.changed_attributes.should include("name")
        @test.changed_attributes.should_not include("age")
      end

      it "should mark attributes as dirty when providing them as arguments" do
        test = DirtyTest.for(@uri, :name => "Steve")

        @test.changed_attributes.should_not include("name")
        @test.changed_attributes.should_not include("age")
      end
    end

    context "that are lists" do
      it "should not mark attributes as dirty when loading" do
        @test.changed_attributes.should_not include("items")
      end

      it "should mark the projection as dirty if an attribute is dirty" do
        @test.items = ["Steve"]
        @test.changed_attributes.should include("items")
      end

      it "should mark attributes as dirty when changed" do
        @test.items = ["Steve"]
        @test.changed_attributes.should include("items")
        @test.changed_attributes.should_not include("age")
      end
  
      it "should not mark attributes as dirty when providing them as arguments" do
        test = DirtyTest.for(@uri, :items => ["Steve"])

        @test.changed_attributes.should_not include("items")
        @test.changed_attributes.should_not include("age")
      end

      it "should mark attributes as dirty when updated" do
        # TODO: a fix is pending for this, read comments on #persist! method
        pending "ActiveModel::Dirty cannot track that - read its docs"
        @test.items << "Steve"
        @test.changed_attributes.should include(:items)
      end

    end
  end

end
