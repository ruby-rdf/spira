
class RubyProps

  include Spira::Resource
  
  default_vocabulary RDF::URI.new('http://example.org/vocab')
  default_base_uri RDF::URI.new('http://example.org/props')

  property :integer, :type => Integer
  property :string,  :type => String
  property :float,   :type => Float


end

class XSDProps

  include Spira::Resource
  
  default_vocabulary RDF::URI.new('http://example.org/vocab')
  default_base_uri RDF::URI.new('http://example.org/props')

  property :integer, :type => XSD.integer
  property :string,  :type => XSD.string
  property :float,   :type => XSD.float


end
