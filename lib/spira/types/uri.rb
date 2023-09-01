module Spira::Types

  ##
  # This type takes RDF Resource objects and provides RDF::URI objects for the
  # ruby representation.
  #
  # @see Spira::Type
  # @see https://ruby-rdf.github.io/rdf/RDF/URI.html
  class URI

    include Spira::Type

    def self.unserialize(value)
      RDF::URI(value)
    end

    def self.serialize(value)
      RDF::URI(value)
    end

    register_alias :uri
    register_alias RDF::URI

  end
end
