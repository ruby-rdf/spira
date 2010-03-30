require 'spira'
require 'rdf'

class Person

  include Spira

  # Find and create instances here
  source ::RDF::Repository

  # the base path to find Persons
  base_path "http://example.org/example/people"

  property :name, RDF::RDFS.label, String
  property :age,  RDF::FOAF.age,   Integer


end
