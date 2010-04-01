require File.dirname(__FILE__) + "/spec_helper.rb"

class CDs < RDF::Vocabulary('http://example.org/')
  property :artist
  property :cds
  property :artists
end

class CD

  include Spira::Resource

  default_base_uri CDs.cds

  property :name,   :predicate => DC.title,   :type => XSD.string

  property :artist, :predicate => CDs.artist, :type => :artist

end

class Artist

  include Spira::Resource

  default_base_uri CDs.artists

  property :name, :predicate => DC.title, :type => XSD.string
  
  #has_many :cds, CD


end


describe "Spira Relations" do

  context "a one-to-many relationship" do
  
    before :all do
      require 'rdf/ntriples'
      @cds_repository = RDF::Repository.load(fixture('relations.nt'))
      Spira.add_repository(:default, @cds_repository)
    end

    it "should find the cd" do
      CD.find('nevermind').should be_a CD
    end

    it "should find the artist" do
      Artist.find('nirvana').should be_a Artist
    end

    context "referencing a single uri" do

      before :each do
        @cd = CD.find 'nevermind'
        @artist = Artist.find 'nirvana'
      end

      it "should find a model object for a uri" do
        @cd.artist.should == @artist
      end

      it "should make a valid statement referencing the an assigned objects URI" do
        @kurt = Artist.new 'kurt cobain'
        @cd.artist = @kurt
        statement = @cd.query(:predicate => CDs.artist).first
        statement.subject.should == @cd.uri
        statement.predicate.should == CDs.artist
        statement.object.should == @kurt.uri
      end

    end

  end


end
