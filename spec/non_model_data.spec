require File.dirname(__FILE__) + "/spec_helper.rb"

describe 'Resources with data not associated with a model' do

  before :all do
    require 'rdf/ntriples'
    class ::ExtraDataTest
      include Spira::Resource
      base_uri "http://example.org/example"

      property :property, :predicate => FOAF.age, :type => Integer

      has_many :list,     :predicate => RDFS.label
    end
    @filename = fixture('non_model_data.nt')
  end

  before :each do
    @extra_repo = RDF::Repository.load(@filename)
    Spira.add_repository(:default, @extra_repo)
  end

  context "when multiple objects exist for a property" do
    before :each do
      @example2 = ExtraDataTest.for('example2')
      @uri = @example2.uri
    end

    it "should not raise an error to load a model with multiple instances of a property predicate" do
      lambda { @example = ExtraDataTest.for('example2') }.should_not raise_error
    end

    it "should treat the property as a single property" do
      @example2.property.should be_a Fixnum
    end

    it "should load one of the available property examples as the property" do
      [15,20].should include @example2.property
    end

    it "should only delete one instance of the property on #destroy!" do
      @example2.destroy!

      # We can still load the same URI, because a property for it still exists
      ExtraDataTest.for('example2').should be_a ExtraDataTest

      # One of the FOAF properties has been deleted, but not the other
      @extra_repo.query(:subject => @uri, :predicate => RDF::FOAF.age).count.should == 1
    end

    it "should delete all instances of matching properties on #destroy!" do
      @example2.destroy!

      @extra_repo.query(:subject => @uri, :predicate => RDF::RDFS.label).to_a.should == []
    end

  end

  context "when enumerating statements" do
    before :each do
      @example1 = ExtraDataTest.for('example1')
    end

    it "unspecified model information should appear in the enumeration" do
      pending "full iteration is not yet implemented."
      @example1.should have_predicate RDF::FOAF.name
    end
  end

  context "when deleting" do
    before :each do
      @example1 = ExtraDataTest.for('example1')
      @uri = @example1.uri
    end

    it "should not delete non-model data on Resource#!destroy" do
      @example1.destroy!
      @extra_repo.query(:subject => @uri, :predicate => RDF::FOAF.name).count.should == 1
    end 

    it "should respond to Resource#destroy_resource!" do
      @example1.should respond_to :destroy_resource!
    end

    it "should delete the entire resource with Resource#destroy_resource!, including non-model data" do
      @example1.destroy_resource!
      @extra_repo.query(:subject => @uri).should be_empty
    end
  end

  context "when updating" do
    before :each do
      @example1 = ExtraDataTest.for('example1')
      @uri = @example1.uri
    end

    it "should save model data" do
      @example1.property = 17
      @example1.save!
      @extra_repo.query(:subject => @uri, :predicate => RDF::FOAF.age).count.should == 1
      @extra_repo.first_value(:subject => @uri, :predicate => RDF::FOAF.age).to_i.should == 17
    end

    it "should not affect non-model data" do
      @example1.property = 17
      @example1.save!
      @extra_repo.query(:subject => @uri, :predicate => RDF::FOAF.name).count.should == 1
      @extra_repo.first_value(:subject => @uri, :predicate => RDF::FOAF.name).should == "Not in the model"
    end
  end

end
