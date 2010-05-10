require File.dirname(__FILE__) + "/spec_helper.rb"

describe Spira do

  context "inheritance" do

    before :all do
      class InheritanceItem
        include Spira::Resource

        property :title, :predicate => DC.title, :type => String
        type  SIOC.item
      end

      class InheritancePost < InheritanceItem
        type  SIOC.post
        property :author, :predicate => DC.author
      end

      class InheritedType < InheritanceItem
      end

      class InheritanceForumPost < InheritancePost
      end

      class InheritanceContainer
        include Spira::Resource
        type SIOC.container

        has_many :items, :type => 'InheritanceItem', :predicate => SIOC.container_of
      end

      class InheritanceForum < InheritanceContainer
        type SIOC.forum

        #property :moderator, :predicate => SIOC.has_moderator
      end

    end

    context "when passing properties to children, " do
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

    context "when including modules" do
      before :all do
        module SpiraModule1
          include Spira::Resource
          has_many :names, :predicate => DC.titles
          property :name, :predicate => DC.title, :type => String
        end
  
        module SpiraModule2
          include Spira::Resource
          has_many :authors, :predicate => DC.authors
          property :author, :predicate => DC.author, :type => String
        end

        class ModuleIncluder1
          include Spira::Resource
          include SpiraModule1
          has_many :ages, :predicate => FOAF.ages
          property :age, :predicate => FOAF.age, :type => Integer
        end

        class ModuleIncluder2
          include Spira::Resource
          include SpiraModule1
          include SpiraModule2
          has_many :ages, :predicate => FOAF.ages
          property :age, :predicate => FOAF.age, :type => Integer
        end
      end

      before :each do
        Spira.add_repository(:default, RDF::Repository.new)
        @includer1 = RDF::URI('http://example.org/item').as(ModuleIncluder1)
        @includer2 = RDF::URI('http://example.org/item').as(ModuleIncluder2)
      end

      it "should include a property getter from the module" do
        @includer1.should respond_to :name
      end

      it "should include a property setter from the module" do
        @includer1.should respond_to :name=
      end

      it "should maintain property information for included modules" do
        ModuleIncluder1.properties[:name][:type].should == Spira::Types::String
      end

      it "should maintain propety information for including modules" do
        @includer1.should respond_to :age
        @includer1.should respond_to :age=
        ModuleIncluder1.properties[:age][:type].should == Spira::Types::Integer
      end

      context "when including multiple modules" do
        before :each do
          @includer2 = RDF::URI('http://example.org/item').as(ModuleIncluder2)
        end

        it "should maintain property getters from both modules" do
          @includer2.should respond_to :name
          @includer2.should respond_to :author
        end

        it "should maintain property setters from both modules" do
          @includer2.should respond_to :name=
          @includer2.should respond_to :author=
        end

        it "should maintain property information for included modules" do
          ModuleIncluder2.properties.should have_key :name
          ModuleIncluder2.properties[:name][:type].should == Spira::Types::String
          ModuleIncluder2.properties.should have_key :author
          ModuleIncluder2.properties[:author][:type].should == Spira::Types::String
        end

        it "should maintain property information for the including module" do
          @includer2.should respond_to :age
          @includer2.should respond_to :age=
          ModuleIncluder2.properties[:age][:type].should == Spira::Types::Integer
        end

        it "should maintain the list of lists for the included modules" do
          @includer2.should respond_to :authors
          @includer2.should respond_to :names
          @includer2.authors.should == []
          @includer2.names.should == []
        end

        it "should maintain the list of lists for the including module" do
          @includer2.should respond_to :ages
          @includer2.ages.should == []
        end
      end
    end

  end
end
