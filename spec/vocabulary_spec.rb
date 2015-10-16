require "spec_helper"
# testing out default vocabularies

describe 'default vocabularies' do

  before :all do
    Spira.repository =  RDF::Repository.new
  end

  context "defining classes" do
    it "should allow a property without a predicate if there is a default vocabulary" do
      expect {
        class VocabTestX < Spira::Base
          configure :default_vocabulary => RDF::URI.new('http://example.org/vocabulary/')
          property :test
        end
      }.not_to raise_error
    end

    it "should raise a ResourceDeclarationError to set a property without a default vocabulary" do
      expect {
        class VocabTestY < Spira::Base
          property :test
        end
      }.to raise_error Spira::ResourceDeclarationError
    end

    # FIXME: reexamine this behavior.  Static typing in the DSL?  Why?  Why not create a URI out of anything we can #to_s?
    it "should raise a ResourceDelcarationError to set a predicate without a default vocabulary that is not an RDF::URI" do
      expect {
        class VocabTestY < Spira::Base
          property :test, :predicate => "http://example.org/test"
        end
      }.to raise_error Spira::ResourceDeclarationError
    end
  end

  context "using classes with a default vocabulary" do

    before :all do
      class ::Bubble < Spira::Base
        configure :default_vocabulary => RDF::URI.new('http://example.org/vocab/'),
                  :base_uri => "http://example.org/bubbles/"
        property :year, :type => Integer
        property :name
        property :title, :predicate => RDF::Vocab::DC.title, :type => String
      end
    end

    let(:year) {RDF::URI.new 'http://example.org/vocab/year'}
    let(:name) {RDF::URI.new 'http://example.org/vocab/name'}

    it "should do non-default sets and gets normally" do
      bubble = Bubble.for 'tulips'
      bubble.year = 1500
      bubble.title = "Holland tulip"
      bubble.save!

      expect(bubble.title).to eql "Holland tulip"
      expect(bubble).to have_predicate RDF::Vocab::DC.title
    end
    it "should create a predicate for a given property" do
      bubble = Bubble.for 'dotcom'
      bubble.year = 2000
      bubble.name = 'Dot-com boom'

      bubble.save!
      expect(bubble).to have_predicate year
      expect(bubble).to have_predicate name
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

      let(:name) {RDF::URI.new 'http://example.org/test#name'}

      it "should correctly not append a slash" do
        test = HashVocabTest.for('test1')
        test.name = "test1"
        test.save!
        expect(test).to have_predicate name
      end

    end
  end
end
