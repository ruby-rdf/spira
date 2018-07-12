require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

# Tests serializing and de-serializing with Psych (YAML).

describe Spira, :ruby => "1.9" do
  require 'psych'

  before :all do
    class PsychPerson < Spira::Base
      configure :base_uri => "http://example.org/example/people"
      property :name, :predicate => RDF::RDFS.label
      property :age,  :predicate => RDF::Vocab::FOAF.age,  :type => Integer
    end

    class PsychEmployee < Spira::Base
      property :name, :predicate => RDF::RDFS.label
      property :age,  :predicate => RDF::Vocab::FOAF.age, :type => Integer
    end

    Spira.repository = RDF::Repository.load(fixture('bob.nt'))
  end

  subject {PsychPerson.for(RDF::URI.new('http://example.org/newperson'))}

  it "serializes to YAML" do
    yaml = Psych.dump(subject)
    expect(yaml).to be_a(String)
  end

  it "de-serializes from YAML" do
    yaml = Psych.dump(subject)
    person = Psych.load(yaml)
    expect(person).to eq subject
  end
end
