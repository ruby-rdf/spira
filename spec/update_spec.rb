require "spec_helper"

# Tests update functionality--update, save, destroy

describe Spira do

  before :all do
    class ::UpdateTest < Spira::Base
      configure :base_uri => "http://example.org/example/people"
      property :name, :predicate => RDF::RDFS.label
      property :age,  :predicate => RDF::Vocab::FOAF.age,  :type => Integer
    end
  end

  let(:test_uri) {RDF::URI('http://example.org/example/people')}
  let(:update_repo) {
    RDF::Repository.new do |repo|
      repo << RDF::Statement.new(test_uri, RDF::RDFS.label, 'Test')
      repo << RDF::Statement.new(test_uri, RDF::Vocab::FOAF.age, 15)
    end
  }
  let(:test) {UpdateTest.for(test_uri)}
  before {Spira.repository = update_repo}

  context "when updating" do

    context "via individual setters" do
      it "should allow setting properties" do
        test.name = 'Testing 1 2 3'
        expect(test.name).to eql 'Testing 1 2 3'
      end

      it "should return the newly set value" do
        expect(test.name = 'Testing 1 2 3').to eql 'Testing 1 2 3'
        expect(test.name).to eql 'Testing 1 2 3'
      end
    end

    context "via #update" do
      it "should allow setting a single property" do
        test.update_attributes(:name => "Testing")
        expect(test.name).to eql "Testing"
      end

      it "should allow setting multiple properties" do
        test.update_attributes(:name => "Testing", :age => 10)
        expect(test.name).to eql "Testing"
        expect(test.age).to eql 10
      end

      it "should return self on success" do
        expect(test.update_attributes(:name => "Testing", :age => 10)).to eql test
      end
    end
  end

  context "when saving" do
    # @see validations.spec
    context "via #save!" do
      it "should save a resource's statements to the repository" do
        test.name = "Save"
        test.save!
        expect(update_repo).to have_statement(RDF::Statement.new(test_uri,RDF::RDFS.label,"Save"))
      end

      it "should return self on success" do
        test.name = "Save"
        expect(test.save).to eql test
      end

      it "should raise an exception on failure" do
        expect(test).to receive(:create_or_update).once.and_return(false)
        test.name = "Save"
        expect { test.save! }.to raise_error Spira::RecordNotSaved
      end

      it "should delete all existing statements for updated properties to the repository" do
        update_repo << RDF::Statement.new(test_uri, RDF::RDFS.label, 'Test 1')
        update_repo << RDF::Statement.new(test_uri, RDF::RDFS.label, 'Test 2')
        expect(update_repo.query(:subject => test_uri, :predicate => RDF::RDFS.label).count).to eql 3
        test.name = "Save"
        test.save!
        expect(update_repo.query(:subject => test_uri, :predicate => RDF::RDFS.label).count).to eql 1
        expect(update_repo).to have_statement(RDF::Statement.new(test_uri, RDF::RDFS.label, 'Save'))
      end

      it "should not update properties unless they are dirty" do
        expect(update_repo).to receive(:delete).once.with([test_uri, RDF::RDFS.label, nil])
        test.name = "Save"
        test.save!
      end

      # Tests for a bug wherein the originally loaded attributes were being
      # deleted on save!, not the current ones
      it "should safely delete old repository information on updates" do
        test.age = 16
        test.save!
        test.age = 17
        test.save!
        expect(update_repo.query(:subject => test_uri, :predicate => RDF::Vocab::FOAF.age).size).to eql 1
        expect(update_repo.first_value(:subject => test_uri, :predicate => RDF::Vocab::FOAF.age)).to eql "17"
      end

      it "should not remove non-model data" do
        update_repo << RDF::Statement.new(test_uri, RDF.type, RDF::URI('http://example.org/type'))
        test.name = "Testing 1 2 3"
        test.save!
        expect(update_repo.query(:subject => test_uri, :predicate => RDF.type).size).to eql 1
      end

      it "should not be changed afterwards" do
        test.name = "Test"
        test.save!
        expect(test).not_to be_changed
      end

      it "removes items set to nil from the repository" do
        test.name = nil
        test.save!
        expect(update_repo.query(:subject => test_uri, :predicate => RDF::RDFS.label).size).to eql 0
      end

    end
  end

  context "when destroying" do
    context "after destroyed" do
      before { test.destroy! }

      it "should be able to validate" do
        expect(test).to be_valid
      end

      it "should be frozen" do
        expect(test).to be_frozen
      end
    end

    context "via #destroy" do
      before :each do
        update_repo << RDF::Statement.new(test_uri, RDF::Vocab::FOAF.name, 'Not in model')
        update_repo << RDF::Statement.new(RDF::URI('http://example.org/test'), RDF::RDFS.seeAlso, test_uri)
      end

      it "should return true on success" do
        expect(test.destroy).to be_truthy
      end

      it "should return false on failure" do
        expect(update_repo).to receive(:delete).once.and_return(nil)
        expect(test.destroy).to be_falsey
      end

      it "should raise an exception on failure" do
        expect(update_repo).to receive(:delete).once.and_return(nil)
        expect { test.destroy! }.to raise_error Spira::RecordNotSaved
      end

      it "should delete all statements in the model" do
        test.destroy!
        expect(update_repo).not_to have_predicate(RDF::RDFS.label)
        expect(update_repo).not_to have_predicate(RDF::Vocab::FOAF.age)
      end

      it "should delete all statements not in the model where it is referred to as object" do
        test.destroy!
        expect(update_repo).not_to have_predicate(RDF::RDFS.seeAlso)
      end

      it "should not delete statements with predicates not defined in the model" do
        test.destroy!
        expect(update_repo).to have_predicate(RDF::Vocab::FOAF.name)
      end

    end

  end

  context "when copying" do
    let(:new_uri) {RDF::URI('http://example.org/people/test2')}
    before {update_repo << RDF::Statement.new(test_uri, RDF::Vocab::FOAF.name, 'Not in model')}

    context "with #copy" do
      it "supports #copy" do
        expect(test.respond_to?(:copy)).to be_truthy
      end

      it "copies to a given subject" do
        new = test.copy(new_uri)
        expect(new.subject).to eql new_uri
      end

      it "copies model data" do
        new = test.copy(new_uri)
        expect(new.name).to eql test.name
        expect(new.age).to eql test.age
      end

    end

    context "with #copy!" do
      it "supports #copy!" do
        expect(test.respond_to?(:copy!)).to be_truthy
      end

      it "copies to a given subject" do
        new = test.copy!(new_uri)
        expect(new.subject).to eql new_uri
      end

      it "copies model data" do
        new = test.copy!(new_uri)
        expect(new.name).to eql test.name
        expect(new.age).to eql test.age
      end

      it "saves the copy immediately" do
        new = test.copy!(new_uri)
        expect(update_repo).to have_statement RDF::Statement.new(new_uri, RDF::RDFS.label, test.name)
        expect(update_repo).to have_statement RDF::Statement.new(new_uri, RDF::Vocab::FOAF.age, test.age)
      end
    end
  end

end
