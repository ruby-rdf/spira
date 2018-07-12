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
      property :name,   :predicate => RDF::Vocab::DC.title,   :type => String
      property :artist, :predicate => CDs.artist, :type => 'Artist'
    end

    class ::Artist < Spira::Base
      configure :base_uri => CDs.artists
      property :name, :predicate => RDF::Vocab::DC.title, :type => String
      has_many :cds, :predicate => CDs.has_cd, :type => :CD
      has_many :teams, :predicate => CDs.teams, :type => :Team
    end

    class ::Team < Spira::Base
      configure :base_uri => CDs.teams
      has_many :artists, :predicate => CDs.artist, :type => 'Artist'
    end
  end

  context "when referencing relationships" do
    context "in the root namespace" do
      before :all do
        class ::RootNSTest < Spira::Base
          property :name, :predicate => RDF::Vocab::DC.title, :type => 'RootNSTest'
        end
        Spira.repository = RDF::Repository.new
      end

      it "should find a class based on the string version of the name" do
        test = RootNSTest.new
        subject = test.subject
        test.name = RootNSTest.new
        test.name.save!
        test.save!

        test = subject.as(RootNSTest)
        expect(test.name).to be_a RootNSTest
      end
    end

    context "in the same namespace" do
      before :all do
        module ::NSTest
          class X < Spira::Base
            property :name, :predicate => RDF::Vocab::DC.title, :type => 'Y'
          end
          class Y < Spira::Base
          end
        end
        Spira.repository = RDF::Repository.new
      end

      it "should find a class based on the string version of the name" do
        test = NSTest::X.new
        subject = test.subject
        test.name = NSTest::Y.new

        test.save!

        test = NSTest::X.for(subject)
        expect(test.name).to be_a NSTest::Y
      end
    end

    context "in another namespace" do
      before :all do
        module ::NSTest
          class Z < Spira::Base
            property :name, :predicate => RDF::Vocab::DC.title, :type => 'NSTestA::A'
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
        expect(test.name).to be_a NSTestA::A
      end
    end
  end

  context "with many-to-many relationship" do
    subject(:artist) {Artist.for "Beard"}
    subject(:team) {Team.for "ZZ Top"}

    before :all do
      Spira.repository = RDF::Repository.new
    end

    context "with resources referencing each other" do
      before do
        artist.teams = [team]
        team.artists = [artist]

        artist.save!
        team.save!
      end

      context "when reloading" do
        it "should not cause an infinite loop" do
          expect(artist.reload).to eql artist
        end
      end
    end
  end

  context "with a one-to-many relationship" do
    subject(:artist) {Artist.for "nirvana"}
    subject(:cd) {CD.for 'nevermind'}

    before :each do
      Spira.repository = RDF::Repository.load(fixture('relations.nt'))
      @cd = CD.for 'nevermind'
    end

    it "should find a cd" do
      expect(cd).to be_a CD
    end

    it "should find the artist" do
      expect(artist).to be_a Artist
    end

    it "should find an artist for a cd" do
      expect(cd.artist).to be_a Artist
    end

    it "should find the correct artist for a cd" do
      expect(cd.artist.uri).to eq artist.uri
    end

    it "should find CDs for an artist" do
      cds = artist.cds
      expect(cds).to be_a Array
      expect(cds.find { |cd| cd.name == 'Nevermind' }).to be_truthy
      expect(cds.find { |cd| cd.name == 'In Utero' }).to be_truthy
    end

    it "should not reload an object for a simple reverse relationship" do
      pending "no longer applies as the global cache is gone"

      expect(artist.cds.first.artist).to equal artist
      artist_cd = cd.artist.cds.find { | list_cd | list_cd.uri == cd.uri }
      expect(cd).to equal artist_cd
    end

    it "should find a model object for a uri" do
      expect(cd.artist).to eq artist
    end

    it "should make a valid statement referencing the assigned objects URI" do
      @kurt = Artist.for('kurt cobain')
      cd.artist = @kurt
      cd.query(:predicate => CDs.artist) do |statement|
        expect(statement.subject).to eq cd.uri
        expect(statement.predicate).to eq CDs.artist
        expect(statement.object).to eq @kurt.uri
      end
    end

  end

  context "with invalid relationships" do
    let(:invalid_repo) {RDF::Repository.new}

    before {Spira.repository = invalid_repo}

    context "when accessing a field named for a non-existant class" do

      before do
        class ::RelationsTestA < Spira::Base
          configure :base_uri => CDs.cds
          property :invalid, :predicate => CDs.artist, :type => :non_existant_type
        end

        invalid_repo.insert(RDF::Statement.new(RDF::URI.new(CDs.cds.to_s + "/invalid_b"), CDs.artist, "whatever"))
      end

      it "should raise a NameError when saving an object with the invalid property" do
        expect {
          RelationsTestA.for('invalid_a', :invalid => Object.new).save!
        }.to raise_error NameError
      end

      it "should raise a NameError when accessing the invalid property on an existing object" do
        expect {
          RelationsTestA.for('invalid_b').invalid
        }.to raise_error NameError
      end

    end

    context "when accessing a field for a class that is not a Spira::Resource" do
      before :all do
        class ::RelationsTestB < Spira::Base
          property :invalid, :predicate => RDF::Vocab::DC.title, :type => 'Object'
        end
      end

      it "should should raise a TypeError when saving an object with the invalid property" do
        expect { RelationsTestB.new(:invalid => Object.new).save! }.to raise_error TypeError
      end

      it "should raise a TypeError when accessing the invalid property on an existing object" do
        subject = RDF::Node.new
        invalid_repo.insert [subject, RDF::Vocab::DC.title, 'something']
        expect { RelationsTestB.for(subject).invalid }.to raise_error TypeError
      end
    end
  end
end
