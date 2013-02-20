require "spec_helper"
# testing out default vocabularies

describe 'default vocabularies' do

  before :all do
    @bubble_repo = RDF::Repository.new
    Spira.add_repository(:default, @bubble_repo)
  end

  before :each do
    @vocabulary = RDF::URI.new('http://example.org/vocabulary/')
  end

  context "defining classes" do
    it "should allow a property without a predicate if there is a default vocabulary" do
      lambda {
        class VocabTestX < Spira::Base
          configure :default_vocabulary => RDF::URI.new('http://example.org/vocabulary/')
          property :test
        end
      }.should_not raise_error
    end

    it "should raise a ResourceDeclarationError to set a property without a default vocabulary" do
      lambda {
        class VocabTestY < Spira::Base
          property :test
        end
      }.should raise_error Spira::ResourceDeclarationError
    end

    # FIXME: reexamine this behavior.  Static typing in the DSL?  Why?  Why not create a URI out of anything we can #to_s?
    it "should raise a ResourceDelcarationError to set a predicate without a default vocabulary that is not an RDF::URI" do
      lambda {
        class VocabTestY < Spira::Base
          property :test, :predicate => "http://example.org/test"
        end
      }.should raise_error Spira::ResourceDeclarationError
    end
  end

  context "using classes with a default vocabulary" do

    before :all do
      class ::Bubble < Spira::Base
        configure :default_vocabulary => RDF::URI.new('http://example.org/vocab/'),
                  :base_uri => "http://example.org/bubbles/"
        property :year, :type => Integer
        property :name
        property :title, :predicate => DC.title, :type => String
      end
    end

    before :each do
      @year = RDF::URI.new 'http://example.org/vocab/year'
      @name = RDF::URI.new 'http://example.org/vocab/name'
    end

    it "should do non-default sets and gets normally" do
      bubble = Bubble.for 'tulips'
      bubble.year = 1500
      bubble.title = "Holland tulip"
      bubble.save!

      bubble.title.should == "Holland tulip"
      bubble.should have_predicate RDF::DC.title
    end
    it "should create a predicate for a given property" do
      bubble = Bubble.for 'dotcom'
      bubble.year = 2000
      bubble.name = 'Dot-com boom'

      bubble.save!
      bubble.should have_predicate @year
      bubble.should have_predicate @name
    end

    context "that ends in a hash seperator" do
      before :all do
        class ::DefaultVocabVocab < ::RDF::Vocabulary('http://example.org/test#') ; end

        class ::HashVocabTest < Spira::Base
          configure :default_vocabulary => DefaultVocabVocab,
                    :base_uri => "http://example.org/testing/"
          property :name
        end
      end

      before :each do
        @name = RDF::URI("http://example.org/test#name")
      end

      it "should correctly not append a slash" do
        test = HashVocabTest.for('test1')
        test.name = "test1"
        test.save!
        test.should have_predicate @name
      end

    end
  end



end
