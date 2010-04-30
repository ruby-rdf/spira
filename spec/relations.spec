require File.dirname(__FILE__) + "/spec_helper.rb"

describe "Spira Relations" do

  before :all do
    
    class CDs < RDF::Vocabulary('http://example.org/')
      property :artist
      property :cds
      property :artists
      property :has_cd
    end
    
    class CD
      include Spira::Resource
      base_uri CDs.cds
      property :name,   :predicate => DC.title,   :type => String
      property :artist, :predicate => CDs.artist, :type => 'Artist'
    end
    
    class Artist
      include Spira::Resource
      base_uri CDs.artists
      property :name, :predicate => DC.title, :type => String
      has_many :cds, :predicate => CDs.has_cd, :type => :CD
    end
  end


  context "a one-to-many relationship" do
  
    before :all do
      require 'rdf/ntriples'
      @cds_repository = RDF::Repository.load(fixture('relations.nt'))
      Spira.add_repository(:default, @cds_repository)
      @cd = CD.for 'nevermind'
      @artist = Artist.for 'nirvana'
    end

    it "should find a cd" do
      @cd.should be_a CD
    end

    it "should find the artist" do
      @artist.should be_a Artist
    end

    it "should find an artist for a cd" do
      @cd.artist.should be_a Artist
    end

    it "should find the correct artist for a cd" do
      @cd.artist.uri.should == @artist.uri
    end

    it "should find CDs for an artist" do
      cds = @artist.cds
      cds.should be_a Array
      cds.find { |cd| cd.name == 'Nevermind' }.should be_true
      cds.find { |cd| cd.name == 'In Utero' }.should be_true
    end

    it "should not reload an object for a simple reverse relationship" do
      artist_cd = @cd.artist.cds.find { | list_cd | list_cd.uri == @cd.uri }
      @cd.should equal artist_cd
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

  context "invalid relationships" do

    before :all do
      @invalid_repo = RDF::Repository.new
      Spira.add_repository(:default, @invalid_repo)
    end

    context "accessing a field named for a non-existant class" do
      
      before :all do
        class RelationsTestA
          include Spira::Resource
          base_uri CDs.cds
          property :invalid, :predicate => CDs.artist, :type => :non_existant_type
        end

        @uri_b = RDF::URI.new(CDs.cds.to_s + "/invalid_b")
        @invalid_repo.insert(RDF::Statement.new(@uri_b, CDs.artist, "whatever"))
      end

      it "should fail to save an object with the invalid property" do
        lambda { RelationsTestA.for('invalid_a', :invalid => Object.new).save! }.should raise_error TypeError
      end

      it "should fail to access the invalid field on an existing object" do
        lambda { RelationsTestA.for('invalid_b').invalid }.should raise_error TypeError
      end
    end

  end
end
