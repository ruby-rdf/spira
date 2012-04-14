require "spec_helper"

describe "Spira resources" do

  before :all do
    
    class ::CDs < RDF::Vocabulary('http://example.org/')
      property :artist
      property :cds
      property :artists
      property :has_cd
    end
    
    class ::CD < Spira::Base
      configure :base_uri => CDs.cds
      property :name,   :predicate => DC.title,   :type => String
      property :artist, :predicate => CDs.artist, :type => 'Artist'
    end
    
    class ::Artist < Spira::Base
      configure :base_uri => CDs.artists
      property :name, :predicate => DC.title, :type => String
      has_many :cds, :predicate => CDs.has_cd, :type => :CD
    end
  end

  context "when referencing relationships" do
    context "in the root namespace" do
      before :all do
        class ::RootNSTest < Spira::Base
          property :name, :predicate => DC.title, :type => 'RootNSTest'
        end
        Spira.add_repository!(:default, RDF::Repository.new)
      end

      it "should find a class based on the string version of the name" do
        test = RootNSTest.new
        subject = test.subject
        test.name = RootNSTest.new
        test.name.save!
        test.save!
        
        test = subject.as(RootNSTest)
        test.name.should be_a RootNSTest
      end
    end

    context "in the same namespace" do
      before :all do
        module ::NSTest
          class X < Spira::Base
            property :name, :predicate => DC.title, :type => 'Y'
          end
          class Y < Spira::Base
          end
        end
        Spira.add_repository!(:default, RDF::Repository.new)
      end

      it "should find a class based on the string version of the name" do
        test = NSTest::X.new
        subject = test.subject
        test.name = NSTest::Y.new

        test.save!

        test = NSTest::X.for(subject)
        test.name.should be_a NSTest::Y
      end
    end

    context "in another namespace" do
      before :all do
        module ::NSTest
          class Z < Spira::Base
            property :name, :predicate => DC.title, :type => 'NSTestA::A'
          end
        end
        module ::NSTestA
          class A < Spira::Base
          end
        end
      end 

      it "should find a class based on the string version of the name" do
        test = NSTest::Z.new
        subject = test.subject
        test.name = NSTestA::A.new

        test.save!

        test = NSTest::Z.for(subject)
        test.name.should be_a NSTestA::A
      end
    end
  end


  context "with a one-to-many relationship" do
  
    before :each do
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
      cds.should be_a Set
      cds.find { |cd| cd.name == 'Nevermind' }.should be_true
      cds.find { |cd| cd.name == 'In Utero' }.should be_true
    end

    it "should not reload an object for a simple reverse relationship" do
      @artist.cds.first.artist.should equal @artist
      artist_cd = @cd.artist.cds.find { | list_cd | list_cd.uri == @cd.uri }
      @cd.should equal artist_cd
    end

    it "should find a model object for a uri" do
      @cd.artist.should == @artist
    end

    it "should make a valid statement referencing the assigned objects URI" do
      @kurt = Artist.for('kurt cobain')
      @cd.artist = @kurt
      statement = @cd.query(:predicate => CDs.artist).first
      statement.subject.should == @cd.uri
      statement.predicate.should == CDs.artist
      statement.object.should == @kurt.uri
    end

  end

  context "with invalid relationships" do

    before :all do
      @invalid_repo = RDF::Repository.new
      Spira.add_repository(:default, @invalid_repo)
    end

    context "when accessing a field named for a non-existant class" do
      
      before :all do
        class ::RelationsTestA < Spira::Base
          configure :base_uri => CDs.cds
          property :invalid, :predicate => CDs.artist, :type => :non_existant_type
        end

        @uri_b = RDF::URI.new(CDs.cds.to_s + "/invalid_b")
        @invalid_repo.insert(RDF::Statement.new(@uri_b, CDs.artist, "whatever"))
      end

      it "should raise a NameError when saving an object with the invalid property" do
        lambda {
          RelationsTestA.for('invalid_a', :invalid => Object.new).save!
        }.should raise_error NameError
      end

      it "should raise a NameError when accessing the invalid property on an existing object" do
        lambda {
          RelationsTestA.for('invalid_b').invalid
        }.should raise_error NameError
      end

    end

    context "when accessing a field for a class that is not a Spira::Resource" do
      before :all do
        class ::RelationsTestB < Spira::Base
          property :invalid, :predicate => DC.title, :type => 'Object'
        end
      end
    
      it "should should raise a TypeError when saving an object with the invalid property" do
        lambda { RelationsTestB.new(:invalid => Object.new).save! }.should raise_error TypeError
      end

      it "should raise a TypeError when accessing the invalid property on an existing object" do
        subject = RDF::Node.new
        @invalid_repo.insert [subject, RDF::DC.title, 'something']
        lambda { RelationsTestB.for(subject).invalid }.should raise_error TypeError
      end
    end
  end
end
