require "spec_helper"

describe Spira do

  context "inheritance" do

    before :all do
      class ::InheritanceItem < Spira::Base
        property :title, predicate: RDF::Vocab::DC.title, type: String
        has_many :subtitle, predicate: RDF::Vocab::DC.description, type: String
        type  RDF::Vocab::SIOC.Item
      end

      class ::InheritancePost < ::InheritanceItem
        type  RDF::Vocab::SIOC.Post
        property :creator, predicate: RDF::Vocab::DC.creator
        property :subtitle, predicate: RDF::Vocab::DC.description, type: String
      end

      class ::InheritedType < ::InheritanceItem
      end

      class ::InheritanceForumPost < ::InheritancePost
      end

      class ::InheritanceContainer < Spira::Base
        type RDF::Vocab::SIOC.Container
        has_many :items, type: 'InheritanceItem', predicate: RDF::Vocab::SIOC.container_of
      end

      class ::InheritanceForum < ::InheritanceContainer
        type RDF::Vocab::SIOC.Forum
        #property :moderator, predicate: RDF::Vocab::SIOC.has_moderator
      end
    end

    context "when redeclaring a property in a child" do
      let(:item) {RDF::URI('http://example.org/item').as(InheritanceItem)}
      let(:post) {RDF::URI('http://example.org/post').as(InheritancePost)}

      before {Spira.repository = RDF::Repository.new}

      it "should override the property on the child" do
        expect(post.subtitle).to be_nil
        expect(post).not_to respond_to(:subtitle_ids)
      end

      it "should not override the parent property" do
        expect(item.subtitle).to be_empty
        expect(item).to respond_to(:subtitle_ids)
      end
    end

    context "when passing properties to children" do
      let(:item) {RDF::URI('http://example.org/item').as(InheritanceItem)}
      let(:post) {RDF::URI('http://example.org/post').as(InheritancePost)}
      let(:type) {RDF::URI('http://example.org/type').as(InheritedType)}
      let(:forum) {RDF::URI('http://example.org/forum').as(InheritanceForumPost)}

      before {Spira.repository = RDF::Repository.new}

      it "should respond to a property getter" do
        expect(post).to respond_to :title
      end

      it "should respond to a property setter" do
        expect(post).to respond_to :title=
      end

      it "should respond to a propety getter on a grandchild class" do
        expect(forum).to respond_to :title 
      end

      it "should respond to a propety setter on a grandchild class" do
        expect(forum).to respond_to :title= 
      end

      it "should maintain property metadata" do
        expect(InheritancePost.properties).to have_key :title
        expect(InheritancePost.properties[:title][:type]).to eql Spira::Types::String
      end

      it "should add properties of child classes" do
        expect(post).to respond_to :creator
        expect(post).to respond_to :creator=
        expect(InheritancePost.properties).to have_key :creator
      end

      it "should allow setting a property" do
        post.title = "test title"
        expect(post.title).to eql "test title"
      end

      it "should inherit an RDFS type if one is not given" do
        expect(InheritedType.type).to eql RDF::Vocab::SIOC.Item
      end

      it "should overwrite the RDFS type if one is given" do
        expect(InheritancePost.type).to eql RDF::Vocab::SIOC.Post
      end

      it "should inherit an RDFS type from the most recent ancestor" do
        expect(InheritanceForumPost.type).to eql RDF::Vocab::SIOC.Post
      end

      it "should not define methods on parents" do
        expect(item).not_to respond_to :creator
      end

      it "should not modify the properties of the base class" do
        expect(Spira::Base.properties).to be_empty
      end

      context "when saving properties" do
        before :each do
          post.title = "test title"
          post.save!
          type.title = "type title"
          type.save!
          forum.title = "forum title"
          forum.save!
        end

        it "should save an edited property" do
          expect(InheritancePost.repository.query({subject: post.uri, predicate: RDF::Vocab::DC.title}).count).to eql 1
        end

        it "should save an edited property on a grandchild class" do
          expect(InheritanceForumPost.repository.query({subject: forum.uri, predicate: RDF::Vocab::DC.title}).count).to eql 1
        end

        it "should save the new type" do
          expect(InheritancePost.repository.query({subject: post.uri, predicate: RDF.type, object: RDF::Vocab::SIOC.Post}).count).to eql 1
        end

        it "should not save the supertype for a subclass which has specified one" do
          expect(InheritancePost.repository.query({subject: post.uri, predicate: RDF.type, object: RDF::Vocab::SIOC.Item}).to_a).to be_empty
        end

        it "should save the supertype for a subclass which has not specified one" do
          expect(InheritedType.repository.query({subject: type.uri, predicate: RDF.type, object: RDF::Vocab::SIOC.Item}).count).to eql 1
        end
      end
    end
  end

  describe "multitype classes" do
    before do
      class MultiTypeThing < Spira::Base
        type  RDF::Vocab::SIOC.Item
        type  RDF::Vocab::SIOC.Post
      end

      class InheritedMultiTypeThing < MultiTypeThing
      end

      class InheritedWithTypesMultiTypeThing < MultiTypeThing
        type RDF::Vocab::SIOC.Container
      end
    end

    it "should have multiple types" do
      types = Set.new [RDF::Vocab::SIOC.Item, RDF::Vocab::SIOC.Post]
      expect(MultiTypeThing.types).to eql types
    end

    it "should inherit multiple types" do
      expect(InheritedMultiTypeThing.types).to eql MultiTypeThing.types
    end

    it "should overwrite types" do
      types = Set.new << RDF::Vocab::SIOC.Container
      expect(InheritedWithTypesMultiTypeThing.types).to eql types
    end

    context "when saved" do
      before {Spira.repository = RDF::Repository.new}
      
      before do
        @thing = RDF::URI('http://example.org/thing').as(MultiTypeThing)
        @thing.save!
      end

      it "should store multiple classes" do
        expect(MultiTypeThing.repository.query({subject: @thing.uri, predicate: RDF.type, object: RDF::Vocab::SIOC.Item}).count).to eql 1
        expect(MultiTypeThing.repository.query({subject: @thing.uri, predicate: RDF.type, object: RDF::Vocab::SIOC.Post}).count).to eql 1
      end
    end
  end

  context "base classes" do
    before :all do
      class ::BaseChild < Spira::Base ; end
    end

    it "should have access to Spira DSL methods" do
      expect(BaseChild).to respond_to :property
      expect(BaseChild).to respond_to :base_uri
      expect(BaseChild).to respond_to :has_many
      expect(BaseChild).to respond_to :default_vocabulary
    end
  end
end
