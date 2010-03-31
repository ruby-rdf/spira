require 'spira'

Spira.add_repository(:person, ::RDF::Repository)


class Person

  include Spira::Resource

  default_source :person

  # the default base path to find Persons
  default_base_uri "http://example.org/example/people"

  property :name, RDFS.label, String
  property :age,  FOAF.age,   Integer


end

class Employee

  include Spira::Resource

  default_source :person

  property :name, RDFS.label, String
  property :age, FOAF.age, Integer

end
