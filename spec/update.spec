require File.dirname(__FILE__) + "/spec_helper.rb"

# Tests update functionality--update, save, destroy

describe Spira do

  before :all do
    class ::UpdateTest
      include Spira::Resource
      base_uri "http://example.org/example/people"
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
        @test.update(:name => "Testing")
        @test.name.should == "Testing"
      end

      it "should allow setting multiple properties" do
        @test.update(:name => "Testing", :age => 10)
        @test.name.should == "Testing"
        @test.age.should == 10
      end

      it "should return self on success" do
        (@test.update(:name => "Testing", :age => 10)).should == @test
      end
    end

    context "via #update!" do
      it "should allow setting a single property and immediately save it to the repository" do
        @test.update!(:name => "Testing")
        @test.name.should == "Testing"
        @update_repo.should have_statement(RDF::Statement.new(@test_uri, RDF::RDFS.label, 'Testing'))
      end

      it "should allow setting multiple properties and immediately save them to the repository" do
        @test.update!(:name => "Testing", :age => 10)
        @test.name.should == "Testing"
        @test.age.should == 10
        @update_repo.should have_statement(RDF::Statement.new(@test_uri, RDF::RDFS.label, 'Testing'))
        @update_repo.should have_statement(RDF::Statement.new(@test_uri, RDF::FOAF.age, 10))
      end

      it "should return self on success" do
        (@test.update!(:name => "Testing", :age => 10)).should == @test
      end

      it "should raise an exception on failure" do
        @update_repo.should_receive(:update).once.and_raise(RuntimeError)
        (@test.update!(:name => "Testing", :age => 10)).should raise_error

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
        (@test.save!).should == @test
      end

      it "should raise an exception on failure" do
        # FIXME: not awesome that the test has to know that spira uses :update
        @update_repo.should_receive(:insert).once.and_raise(RuntimeError)
        @test.name = "Save"
        lambda { @test.save! }.should raise_error #FIXME: what kind of error?
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

    end
  end

  context "when destroying" do
    context "via #destroy" do
      before :each do
        @update_repo << RDF::Statement.new(@test_uri, RDF::FOAF.name, 'Not in model')
        @update_repo << RDF::Statement.new(RDF::URI('http://example.org/test'), RDF::RDFS.seeAlso, @test_uri)
      end

      it "should return true on success" do
        @test.destroy!.should == true
      end

      it "should raise an exception on failure" do
        @update_repo.should_receive(:delete).once.and_raise(RuntimeError)
        lambda {@test.destroy!}.should raise_error
      end

      context "without options" do
        it "should delete all statements in the model" do
          @test.destroy!
          @update_repo.count.should == 2
          @update_repo.should_not have_predicate(RDF::RDFS.label)
          @update_repo.should_not have_predicate(RDF::FOAF.age)
        end

        it "should not delete statements with predicates not defined in the model" do
          @test.destroy!
          @update_repo.count.should == 2
          @update_repo.should have_predicate(RDF::FOAF.name)
        end
      end

      context "with :subject" do
        it "should delete all statements with self as the subject" do
          @test.destroy!(:subject)
          @update_repo.should_not have_subject @test_uri
        end

        it "should not delete statements with self as the object" do
          @test.destroy!(:subject)
          @update_repo.should have_object @test_uri
        end
      end

      context "with :object" do
        it "should delete all statements with self as the object" do
          @test.destroy!(:object)
          @update_repo.should_not have_object @test_uri
        end

        it "should not delete statements with self as the subject" do
          @test.destroy!(:object)
          @update_repo.should have_subject @test_uri
          @update_repo.query(:subject => @test_uri).count.should == 3
        end
      end

      context "with :completely" do
        it "should delete all statements referencing the object" do
          @test.destroy!(:completely)
          @update_repo.count.should == 0
        end
      end

    end

  end
    
end
