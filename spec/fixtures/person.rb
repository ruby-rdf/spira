require 'spira'
require 'rdf'

Spira.add_repository(:person, ::RDF::Repository)


class Person

  include Spira::Resource

  default_source :person

  # the default base path to find Persons
  base_path "http://example.org/example/people"

  property :name, RDFS.label, String
  property :age,  FOAF.age,   Integer


end
