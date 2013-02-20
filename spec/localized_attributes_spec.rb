# encoding:utf-8
require "spec_helper"

# # Tests of basic functionality--getting, setting, creating, saving, when no
# # relations or anything fancy are involved.

describe Spira do

  before :all do
    require 'rdf/ntriples'

    class ::Concept < Spira::Base
      configure :base_uri => "http://example.org/example/"
      has_many :label, :predicate => RDFS.label, :localized => true
      property :num_employees, :predicate => RDF::URI.new('http://example.org/example/identifier')
    end
  end

  let(:company) {
    ::Concept.for('http://example.org/example/company')
  }

  before :each do
    @repository = RDF::Repository.load(fixture('localized.nt'))
    Spira.add_repository(:default, @repository)
  end

  context "with a localized property" do
    it "should have the default getter" do
      company.should respond_to :label
    end

    it "should have a _native getter" do
      company.should respond_to :label_native
    end

    it "should have a _with_locales getter" do
      company.should respond_to :label_with_locales
    end

    describe "the default getter" do
      it "should take in account the current locale" do
        I18n.locale = :en
        company.label.should == "company"
        I18n.locale = :fr
        company.label.should == "société"
      end
    end

    describe "the _native getter" do
      it "should return all the labels" do
        company.label_native.should have(2).elements
      end

      it "should return the labels as RDF Literals" do
        company.label_native.first.should be_a(RDF::Literal)
      end
    end

    describe "the _with_locales getter" do
      it "should return a hash" do
        company.label_with_locales.should be_a(Hash)
      end

      it "should contains all the locales" do
        company.label_with_locales.keys.should include(:fr, :en)
      end

      it "should contains all the labels" do
        company.label_with_locales[:fr].should == 'société'
      end
    end

    describe "the default setter" do
      it "should take in account the current locale" do
        I18n.locale = :en
        company.label = nil
        I18n.locale = :fr
        company.label.should == "société"
      end
    end

    describe "the _native setter" do
      it "should be locale independant" do
        company.label_native = [RDF::Literal.new('Company', :language => :en)]
        company.label_native.should have(1).elements
      end
    end

    describe "the _with_locales setter" do
      it "should be locale independant" do
        company.label_with_locales = { :en => 'Company', :fr => 'Société' }
        company.label_native.should have(2).elements
      end
    end
  end
end
