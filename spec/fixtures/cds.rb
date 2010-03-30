require 'spira'

class CDs < RDF::Vocabulary('http://example.org/')
  property :artist
  property :cds
  property :artists
end

class CD

  include Spira::Resource

  default_base_uri CDs.cds

  property :name, DC.title , XSD.string

  property :artist, CDs.artist, :artist

end

class Artist

  include Spira::Resource

  default_base_uri CDs.artists

  property :name, DC.title, XSD.string
  
  #has_many :cds, CD


end
