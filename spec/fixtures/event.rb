# Fixture to test :default repository loading


Spira.add_repository(:default, ::RDF::Repository)

class Event
  include Spira::Resource

  property :name, :predicate => DC.title

end

class Stadium
  include Spira::Resource

  property :name, :predicate => DC.title

  default_source :stadium

end
