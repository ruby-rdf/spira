require 'spira'

class CDs < RDF::Vocabulary('http://example.org/')
  property :artist
  property :cds
  property :artists
end

class CD

  include Spira::Resource

  default_base_uri CDs.cds

  property :name,   :predicate => DC.title,   :type => XSD.string

  property :artist, :predicate => CDs.artist, :type => :artist

end

class Artist

  include Spira::Resource

  default_base_uri CDs.artists

  property :name, :predicate => DC.title, :type => XSD.string
  
  #has_many :cds, CD


end
