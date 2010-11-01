require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

describe 'Spira resources' do

  before :all do
    class ::HookTest < ::Spira::Base
      property :name, :predicate => FOAF.name
    end
    @subject = RDF::URI.intern('http://example.org/test')
  end

  context "with a before_create method" do
    before :all do
      class ::BeforeCreateTest < ::HookTest
        type FOAF.bc_test

       def before_create
          self.name = "Everyone has this name"
        end
      end

      class ::BeforeCreateWithoutTypeTest < ::HookTest
        def before_create
          self.name = "Everyone has this name"
        end
      end
    end

    before :each do
      @repository = RDF::Repository.new
      @repository << RDF::Statement.new(@subject, RDF.type, RDF::FOAF.bc_test)
      @repository << RDF::Statement.new(@subject, RDF::FOAF.name, "A name")
      Spira.add_repository(:default, @repository)
    end

    it "calls the before_create method before saving a resouce for the first time" do
      test = RDF::URI('http://example.org/new').as(::BeforeCreateTest)
      test.save!
      test.name.should == "Everyone has this name"
      @repository.should have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the before_create method if the resource previously existed" do
      test = @subject.as(::BeforeCreateTest)
      test.save!
      test.name.should == "A name"
      @repository.should have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "A name")
      @repository.should_not have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end

    it "does not call the before_create method without a type declaration" do
      test = RDF::URI('http://example.org/new').as(::BeforeCreateWithoutTypeTest)
      test.save!
      @repository.should_not have_statement RDF::Statement.new(test.subject, RDF::FOAF.name, "Everyone has this name")
    end
  end

  context "with an after_create method" do
    it "calls the after_create method after saving a resource for the first time" do

    end

    it "does not call after_create if the resource previously existed" do
    end
  end

  context "with a before_update method" do
    it "calls the before_update method before updating a field" do

    end
  end

  context "with an after_update method" do
    it "calls the after_update method after updating a field" do

    end
  end

  context "with a before_save method" do
    it "calls the before_save method before saving" do
    end
  end

  context "with an after_save method" do
    it "calls the after_save method after saving" do
    end

  end

  context "with a before_destroy method" do
    it "calls the before_destroy method before destroying" do
    end
  end

  context "with an after_destroy method" do
    it "calls the after_destroy method after destroying" do
    end
  end

end
