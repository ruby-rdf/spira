
# testing out default vocabularies

class Bubble

  include Spira::Resource

  default_vocabulary RDF::URI.new 'http://example.org/vocab/'

  default_base_uri "http://example.org/bubbles/"

  property :year, :type => Integer
  property :name

  property :title, :predicate => DC.title, :type => String

end
