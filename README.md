# Spira

Bringing linked data to life

Spira is a framework for using the information in RDF.rb repositories as model objects.

Example:

    class Person
      base_path "http://example.org/example/people"
      source ::RDF::Repository
    
      property :name, RDF::FOAF.name, String
      property :age,  RDF::FOAF.age,  Integer

    end

    bob = Person.create 'bob'
    bob.age  = 15
    bob.name = "Bob Smith"
    bob.save!

    bob.each_statement
    #<http://example.org/example/people/bob> <http://xmlns.com/foaf/0.1/age> "15"^^<http://www.w3.org/2001/XMLSchema#integer> .
    #<http://example.org/example/people/bob> <http://www.w3.org/2000/01/rdf-schema#label> "Bob Smith" .
    
You probably don't want to be using this yet.  Major changes are still forthcoming.
