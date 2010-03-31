# Fixture to test :default repository loading


Spira.add_repository(:default, ::RDF::Repository)

class Event
  include Spira::Resource

  property :name, DC.title, String

end

class Stadium
  include Spira::Resource

  property :name, DC.title, String

  default_source :stadium

end
