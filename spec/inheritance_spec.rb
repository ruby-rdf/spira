require "spec_helper"

describe Spira do

  context "inheritance" do

    before :all do
      class ::InheritanceItem < Spira::Base
        property :title, :predicate => DC.title, :type => String
        type  SIOC.item
      end

      class ::InheritancePost < ::InheritanceItem
        type  SIOC.post
        property :author, :predicate => DC.author
      end

      class ::InheritedType < ::InheritanceItem
      end

      class ::InheritanceForumPost < ::InheritancePost
      end

      class ::InheritanceContainer < Spira::Base
        type SIOC.container
        has_many :items, :type => 'InheritanceItem', :predicate => SIOC.container_of
      end

      class ::InheritanceForum < ::InheritanceContainer
        type SIOC.forum
        #property :moderator, :predicate => SIOC.has_moderator
      end
    end

    context "when passing properties to children" do
      before :each do
        Spira.add_repository(:default, RDF::Repository.new)
        @item = RDF::URI('http://example.org/item').as(InheritanceItem)
        @post = RDF::URI('http://example.org/post').as(InheritancePost)
        @type = RDF::URI('http://example.org/type').as(InheritedType)
        @forum = RDF::URI('http://example.org/forum').as(InheritanceForumPost)
      end

      it "should respond to a property getter" do
        @post.should respond_to :title
      end

      it "should respond to a property setter" do
        @post.should respond_to :title=
      end

      it "should respond to a propety getter on a grandchild class" do
        @forum.should respond_to :title 
      end

      it "should respond to a propety setter on a grandchild class" do
        @forum.should respond_to :title= 
      end

      it "should maintain property metadata" do
        InheritancePost.properties.should have_key :title
        InheritancePost.properties[:title][:type].should == Spira::Types::String
      end

      it "should add properties of child classes" do
        @post.should respond_to :author
        @post.should respond_to :author=
        InheritancePost.properties.should have_key :author
      end

      it "should allow setting a property" do
        @post.title = "test title"
        @post.title.should == "test title"
      end

      it "should inherit an RDFS type if one is not given" do
        InheritedType.type.should == RDF::SIOC.item
      end

      it "should overwrite the RDFS type if one is given" do
        InheritancePost.type.should == RDF::SIOC.post
      end

      it "should inherit an RDFS type from the most recent ancestor" do
        InheritanceForumPost.type.should == RDF::SIOC.post
      end

      it "should not define methods on parents" do
        @item.should_not respond_to :author
      end

      it "should not modify the properties of the base class" do
        Spira::Base.properties.should be_empty
      end

      context "when saving properties" do
        before :each do
          @post.title = "test title"
          @post.save!
          @type.title = "type title"
          @type.save!
          @forum.title = "forum title"
          @forum.save!
        end

        it "should save an edited property" do
          InheritancePost.repository.query(:subject => @post.uri, :predicate => RDF::DC.title).count.should == 1
        end

        it "should save an edited property on a grandchild class" do
          InheritanceForumPost.repository.query(:subject => @forum.uri, :predicate => RDF::DC.title).count.should == 1
        end

        it "should save the new type" do
          InheritancePost.repository.query(:subject => @post.uri, :predicate => RDF.type, :object => RDF::SIOC.post).count.should == 1
        end

        it "should not save the supertype for a subclass which has specified one" do
          InheritancePost.repository.query(:subject => @post.uri, :predicate => RDF.type, :object => RDF::SIOC.item).count.should == 0
        end

        it "should save the supertype for a subclass which has not specified one" do
          InheritedType.repository.query(:subject => @type.uri, :predicate => RDF.type, :object => RDF::SIOC.item).count.should == 1
        end
      end
    end
  end

  describe "multitype classes" do
    before do
      class MultiTypeThing < Spira::Base
        type  SIOC.item
        type  SIOC.post
      end

      class InheritedMultiTypeThing < MultiTypeThing
      end

      class InheritedWithTypesMultiTypeThing < MultiTypeThing
        type SIOC.container
      end
    end

    it "should have multiple types" do
      types = Set.new [RDF::SIOC.item, RDF::SIOC.post]
      MultiTypeThing.types.should eql types
    end

    it "should inherit multiple types" do
      InheritedMultiTypeThing.types.should eql MultiTypeThing.types
    end

    it "should overwrite types" do
      types = Set.new << RDF::SIOC.container
      InheritedWithTypesMultiTypeThing.types.should eql types
    end

    context "when saved" do
      before do
        @thing = RDF::URI('http://example.org/thing').as(MultiTypeThing)
        @thing.save!
      end

      it "should store multiple classes" do
        MultiTypeThing.repository.query(:subject => @thing.uri, :predicate => RDF.type, :object => RDF::SIOC.item).count.should == 1
        MultiTypeThing.repository.query(:subject => @thing.uri, :predicate => RDF.type, :object => RDF::SIOC.post).count.should == 1
      end
    end
  end

  context "base classes" do
    before :all do
      class ::BaseChild < Spira::Base ; end
    end

    it "should have access to Spira DSL methods" do
      BaseChild.should respond_to :property
      BaseChild.should respond_to :base_uri
      BaseChild.should respond_to :has_many
      BaseChild.should respond_to :default_vocabulary
    end
  end
end
