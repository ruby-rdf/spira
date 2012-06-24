require "spec_helper"

# Tests update functionality--update, save, destroy

describe Spira do

  before :all do
    class ::UpdateTest < Spira::Base
      configure :base_uri => "http://example.org/example/people"
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age,  :type => Integer
    end
  end

  before :each do
    @test_uri = RDF::URI('http://example.org/example/people')
    @update_repo = RDF::Repository.new
    @update_repo << RDF::Statement.new(@test_uri, RDF::RDFS.label, 'Test')
    @update_repo << RDF::Statement.new(@test_uri, RDF::FOAF.age, 15)
    Spira.add_repository(:default, @update_repo)
    @test = UpdateTest.for(@test_uri)
  end

  context "when updating" do

    context "via individual setters" do
      it "should allow setting properties" do
        @test.name = 'Testing 1 2 3'
        @test.name.should == 'Testing 1 2 3'
      end

      it "should return the newly set value" do
        (@test.name = 'Testing 1 2 3').should == 'Testing 1 2 3'
        @test.name.should == 'Testing 1 2 3'
      end
    end

    context "via #update" do
      it "should allow setting a single property" do
        @test.update_attributes(:name => "Testing")
        @test.name.should == "Testing"
      end

      it "should allow setting multiple properties" do
        @test.update_attributes(:name => "Testing", :age => 10)
        @test.name.should == "Testing"
        @test.age.should == 10
      end

      it "should return self on success" do
        (@test.update_attributes(:name => "Testing", :age => 10)).should == @test
      end
    end
  end

  context "when saving" do
    # @see validations.spec
    context "via #save!" do
      it "should save a resource's statements to the repository" do
        @test.name = "Save"
        @test.save!
        @update_repo.should have_statement(RDF::Statement.new(@test_uri,RDF::RDFS.label,"Save"))
      end

      it "should return self on success" do
        @test.name = "Save"
        @test.save.should == @test
      end

      it "should raise an exception on failure" do
        @test.should_receive(:create_or_update).once.and_return(false)
        @test.name = "Save"
        lambda { @test.save! }.should raise_error Spira::RecordNotSaved
      end

      it "should delete all existing statements for updated properties to the repository" do
        @update_repo << RDF::Statement.new(@test_uri, RDF::RDFS.label, 'Test 1')
        @update_repo << RDF::Statement.new(@test_uri, RDF::RDFS.label, 'Test 2')
        @update_repo.query(:subject => @test_uri, :predicate => RDF::RDFS.label).count.should == 3
        @test.name = "Save"
        @test.save!
        @update_repo.query(:subject => @test_uri, :predicate => RDF::RDFS.label).count.should == 1
        @update_repo.should have_statement(RDF::Statement.new(@test_uri, RDF::RDFS.label, 'Save'))
      end

      it "should not update properties unless they are dirty" do
        @update_repo.should_receive(:delete).once.with([@test_uri, RDF::RDFS.label, nil])
        @test.name = "Save"
        @test.save!
      end

      # Tests for a bug wherein the originally loaded attributes were being
      # deleted on save!, not the current ones
      it "should safely delete old repository information on updates" do
        @test.age = 16
        @test.save!
        @test.age = 17
        @test.save!
        @update_repo.query(:subject => @test_uri, :predicate => RDF::FOAF.age).size.should == 1
        @update_repo.first_value(:subject => @test_uri, :predicate => RDF::FOAF.age).should == "17"
      end

      it "should not remove non-model data" do
        @update_repo << RDF::Statement.new(@test_uri, RDF.type, RDF::URI('http://example.org/type'))
        @test.name = "Testing 1 2 3"
        @test.save!
        @update_repo.query(:subject => @test_uri, :predicate => RDF.type).size.should == 1
      end

      it "should not be changed afterwards" do
        @test.name = "Test"
        @test.save!
        @test.should_not be_changed
      end

      it "removes items set to nil from the repository" do
        @test.name = nil
        @test.save!
        @update_repo.query(:subject => @test_uri, :predicate => RDF::RDFS.label).size.should == 0
      end

    end
  end

  context "when destroying" do
    context "after destroyed" do
      before { @test.destroy! }

      it "should be able to validate" do
        @test.should be_valid
      end

      it "should be frozen" do
        @test.should be_frozen
      end
    end

    context "via #destroy" do
      before :each do
        @update_repo << RDF::Statement.new(@test_uri, RDF::FOAF.name, 'Not in model')
        @update_repo << RDF::Statement.new(RDF::URI('http://example.org/test'), RDF::RDFS.seeAlso, @test_uri)
      end

      it "should return true on success" do
        @test.destroy.should be_true
      end

      it "should return false on failure" do
        @update_repo.should_receive(:delete).once.and_return(nil)
        @test.destroy.should be_false
      end

      it "should raise an exception on failure" do
        @update_repo.should_receive(:delete).once.and_return(nil)
        lambda { @test.destroy! }.should raise_error Spira::RecordNotSaved
      end

      it "should delete all statements in the model" do
        @test.destroy!
        @update_repo.should_not have_predicate(RDF::RDFS.label)
        @update_repo.should_not have_predicate(RDF::FOAF.age)
      end

      it "should delete all statements not in the model where it is referred to as object" do
        @test.destroy!
        @update_repo.should_not have_predicate(RDF::RDFS.seeAlso)
      end

      it "should not delete statements with predicates not defined in the model" do
        @test.destroy!
        @update_repo.should have_predicate(RDF::FOAF.name)
      end

    end

  end

  context "when copying" do
    before :each do
      @new_uri = RDF::URI('http://example.org/people/test2')
      @update_repo << RDF::Statement.new(@test_uri, RDF::FOAF.name, 'Not in model')
    end

    context "with #copy" do
      it "supports #copy" do
        @test.respond_to?(:copy).should be_true
      end

      it "copies to a given subject" do
        new = @test.copy(@new_uri)
        new.subject.should == @new_uri
      end

      it "copies model data" do
        new = @test.copy(@new_uri)
        new.name.should == @test.name
        new.age.should == @test.age
      end

    end

    context "with #copy!" do
      it "supports #copy!" do
        @test.respond_to?(:copy!).should be_true
      end

      it "copies to a given subject" do
        new = @test.copy!(@new_uri)
        new.subject.should == @new_uri
      end

      it "copies model data" do
        new = @test.copy!(@new_uri)
        new.name.should == @test.name
        new.age.should == @test.age
      end

      it "saves the copy immediately" do
        new = @test.copy!(@new_uri)
        @update_repo.should have_statement RDF::Statement.new(@new_uri, RDF::RDFS.label, @test.name)
        @update_repo.should have_statement RDF::Statement.new(@new_uri, RDF::FOAF.age, @test.age)
      end
    end
  end

end
