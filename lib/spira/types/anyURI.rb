module Spira::Types

  ##
  # A {Spira::Type} for URI values.  Values will be associated with the
  # `XSD.anyURI` type with no language code.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::AnyURI`, `AnyURI`, or `XSD.anyURI`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class AnyURI

    include Spira::Type

    def self.unserialize(value)
      value.object
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.anyURI)
    end

    register_alias RDF::XSD.anyURI

  end
end
