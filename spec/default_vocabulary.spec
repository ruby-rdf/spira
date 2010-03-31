require File.dirname(__FILE__) + "/spec_helper.rb"


describe 'default vocabularies' do

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
      require 'bubbles'
    end

    before :each do
      @year = RDF::URI.new 'http://example.org/vocab/year'
      @name = RDF::URI.new 'http://example.org/vocab/name'
    end

    it "should do non-default sets and gets normally" do
      bubble = Bubble.create 'tulips'
      bubble.year = 1500
      bubble.title = "Holland tulip"
      bubble.save!

      bubble.title.should == "Holland tulip"
      bubble.should have_predicate RDF::DC.title
    end
    it "should create a predicate for a given property" do
      bubble = Bubble.create 'dotcom'
      bubble.year = 2000
      bubble.name = 'Dot-com boom'

      bubble.save!
      bubble.should have_predicate @year
      bubble.should have_predicate @name
    end
  end



end
