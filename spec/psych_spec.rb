require File.dirname(File.expand_path(__FILE__)) + '/spec_helper'

# Tests serializing and de-serializing with Psych (YAML).

describe Spira, :ruby => "1.9" do
  require 'psych'

  before :all do
    class PsychPerson < Spira::Base
      configure :base_uri => "http://example.org/example/people"
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age,  :type => Integer
    end
    
    class PsychEmployee < Spira::Base
      property :name, :predicate => RDFS.label
      property :age,  :predicate => FOAF.age, :type => Integer
    end

    require 'rdf/ntriples'
    @person_repository = RDF::Repository.load(fixture('bob.nt'))
    Spira.add_repository(:default, @person_repository)
  end

  before :each do
    @person_repository = RDF::Repository.load(fixture('bob.nt'))
    Spira.add_repository(:default, @person_repository)

    @person = PsychPerson.for(RDF::URI.new('http://example.org/newperson'))
  end

  it "serializes to YAML" do
    yaml = Psych.dump(@person)
    yaml.should be_a(String)
  end

  it "de-serializes from YAML" do
    yaml = Psych.dump(@person)
    person2 = Psych.load(yaml)
    person2.should == @person
  end
end
