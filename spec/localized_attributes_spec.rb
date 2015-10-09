# encoding:utf-8
require "spec_helper"

# # Tests of basic functionality--getting, setting, creating, saving, when no
# # relations or anything fancy are involved.

describe Spira do

  before :all do
    class ::Concept < Spira::Base
      configure :base_uri => "http://example.org/example/"
      property :label, :predicate => RDFS.label, :localized => true
      property :num_employees, :predicate => RDF::URI.new('http://example.org/example/identifier')
    end
  end

  let(:company) {
    ::Concept.for('http://example.org/example/company')
  }

  before {Spira.repository =  RDF::Repository.load(fixture('localized.nt'))}

  context "with a localized property" do
    it "should have the default getter" do
      expect(company).to respond_to :label
    end

    it "should have a _native getter" do
      expect(company).to respond_to :label_native
    end

    it "should have a _with_locales getter" do
      expect(company).to respond_to :label_with_locales
    end

    describe "the default getter" do
      it "should take in account the current locale" do
        I18n.locale = :en
        expect(company.label).to eql "company"
        I18n.locale = :fr
        expect(company.label).to eql "société"
      end
    end

    describe "the _native getter" do
      it "should return all the labels" do
        expect(company.label_native.length).to eql 2
      end

      it "should return the labels as RDF Literals" do
        expect(company.label_native.first).to be_a(RDF::Literal)
      end
    end

    describe "the _with_locales getter" do
      it "should return a hash" do
        expect(company.label_with_locales).to be_a(Hash)
      end

      it "should contains all the locales" do
        expect(company.label_with_locales.keys).to include(:fr, :en)
      end

      it "should contains all the labels" do
        expect(company.label_with_locales[:fr]).to eql 'société'
      end
    end

    describe "the default setter" do
      it "should take in account the current locale" do
        I18n.locale = :en
        company.label = nil
        I18n.locale = :fr
        expect(company.label).to eql "société"
      end
    end

    describe "the _native setter" do
      it "should be locale independant" do
        company.label_native = [RDF::Literal.new('Company', :language => :en)]
        expect(company.label_native.length).to eql 1
      end
    end

    describe "the _with_locales setter" do
      it "should be locale independant" do
        company.label_with_locales = { :en => 'Company', :fr => 'Société' }
        expect(company.label_native.length).to eql 2
      end
    end
  end
end
