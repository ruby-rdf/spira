require File.dirname(__FILE__) + "/spec_helper.rb"
# testing out default vocabularies

class Bubble

  include Spira::Resource

  default_vocabulary RDF::URI.new 'http://example.org/vocab/'

  base_uri "http://example.org/bubbles/"

  property :year, :type => Integer
  property :name

  property :title, :predicate => DC.title, :type => String

end


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
        class X
          include Spira::Resource
          default_vocabulary RDF::URI.new('http://example.org/vocabulary/')
          property :test
        end
      }.should_not raise_error
    end

    it "should raise an error to set a proeprty without a default vocabulary" do
      lambda {
        class Y
          include Spira::Resource
          property :test
        end
      }.should raise_error TypeError

    end

  end

  context "using classes with a default vocabulary" do

    before :all do
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
  end



end
