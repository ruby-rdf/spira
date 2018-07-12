require "spec_helper"

describe 'Resources with data not associated with a model' do

  before :all do
    class ::ExtraDataTest < Spira::Base
      configure :base_uri => "http://example.org/example"

      property :property, :predicate => RDF::Vocab::FOAF.age, :type => Integer
      has_many :list,     :predicate => RDF::RDFS.label
    end
  end
  let(:extra_repo) {RDF::Repository.load(fixture('non_model_data.nt'))}

  before {Spira.repository = extra_repo}

  context "when multiple objects exist for a property" do
    subject {ExtraDataTest.for('example2')}

    it "should not raise an error to load a model with multiple instances of a property predicate" do
      expect { ExtraDataTest.for('example2') }.not_to raise_error
    end

    its(:property) {is_expected.to be_a Fixnum}

    it "should load one of the available property examples as the property" do
      expect([15,20]).to include subject.property
    end

  end

  context "when deleting" do
    subject {ExtraDataTest.for('example1')}

    it "should not delete non-model data on Resource#!destroy" do
      subject.destroy!
      expect(extra_repo.query(:subject => subject.uri, :predicate => RDF::Vocab::FOAF.name).count).to eql 1
    end

  end

  context "when updating" do
    subject {ExtraDataTest.for('example1')}

    it "should save model data" do
      subject.property = 17
      subject.save!
      expect(extra_repo.query(:subject => subject.uri, :predicate => RDF::Vocab::FOAF.age).count).to eql 1
      expect(extra_repo.first_value(:subject => subject.uri, :predicate => RDF::Vocab::FOAF.age).to_i).to eql 17
    end

    it "should not affect non-model data" do
      subject.property = 17
      subject.save!
      expect(extra_repo.query(:subject => subject.uri, :predicate => RDF::Vocab::FOAF.name).count).to eql 1
      expect(extra_repo.first_value(:subject => subject.uri, :predicate => RDF::Vocab::FOAF.name)).to eql "Not in the model"
    end
  end

end
