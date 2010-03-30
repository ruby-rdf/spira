require File.dirname(__FILE__) + "/spec_helper.rb"


describe "Spira Relations" do

  context "a one-to-many relationship" do
  
    before :all do
      require 'cds'
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
    
    end

  end


end
