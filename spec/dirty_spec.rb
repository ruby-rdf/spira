require "spec_helper"

describe Spira do

  before :all do
    class ::DirtyTest < Spira::Base
      property :name,  :predicate => RDF::RDFS.label
      property :age,   :predicate => RDF::Vocab::FOAF.age,  :type => Integer
      has_many :items, :predicate => RDF::RDFS.seeAlso
    end
  end

  let(:uri) {RDF::URI("http://example.org/example/people/alice")}
  before :each do
    Spira.repository = RDF::Repository.new do |repo|
      repo << RDF::Statement.new(uri, RDF::RDFS.label, "Alice")
      repo << RDF::Statement.new(uri, RDF::Vocab::FOAF.age, 15)
      repo << RDF::Statement.new(uri, RDF::RDFS.seeAlso, "A Literal")
      repo << RDF::Statement.new(uri, RDF::RDFS.seeAlso, "Another Literal")
    end
  end

  context "when tracking dirty attributes" do
    subject {DirtyTest.for(uri)}

    it {is_expected.not_to be_changed}

    context "that are properties" do

      it "should not mark attributes as dirty when loading" do
        expect(subject.changed_attributes).not_to include("name")
        expect(subject.changed_attributes).not_to include("age")
      end
  
      it "should mark the projection as dirty if an attribute is dirty" do
        subject.name = "Steve"
        is_expected.to be_changed
      end
  
      it "should mark attributes as dirty when changed" do
        subject.name = "Steve"
        expect(subject.changed_attributes).to include("name")
        expect(subject.changed_attributes).not_to include("age")
      end

      it "should mark attributes as dirty when providing them as arguments" do
        expect(subject.changed_attributes).not_to include("name")
        expect(subject.changed_attributes).not_to include("age")
      end
    end

    context "that are lists" do
      its(:changed_attributes) {is_expected.not_to include("items")}

      it "should mark the projection as dirty if an attribute is dirty" do
        subject.items = ["Steve"]
        expect(subject.changed_attributes).to include("items")
      end

      it "should mark attributes as dirty when changed" do
        subject.items = ["Steve"]
        expect(subject.changed_attributes).to include("items")
        expect(subject.changed_attributes).not_to include("age")
      end
  
      it "should not mark attributes as dirty when providing them as arguments" do
        expect(subject.changed_attributes).not_to include("items")
        expect(subject.changed_attributes).not_to include("age")
      end

      it "should mark attributes as dirty when updated" do
        # TODO: a fix is pending for this, read comments on #persist! method
        pending "ActiveModel::Dirty cannot track that - read its docs"
        subject.items << "Steve"
        expect(subject.changed_attributes).to include(:items)
      end

    end
  end

end
