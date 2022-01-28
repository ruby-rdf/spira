module Spira::Types

  ##
  # A {Spira::Type} for dateTimes.  Values will be associated with the
  # `XSD.dateTime` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::DateTime`, `DateTime`, or `XSD.dateTime`.
  #
  # @see Spira::Type
  # @see https://ruby-rdf.github.io/rdf/RDF/Literal.html
  class DateTime
    include Spira::Type

    def self.unserialize(value)
      object = value.object
    end

    def self.serialize(value)
      RDF::Literal.new(value, datatype: XSD.dateTime)
    end

    register_alias RDF::XSD.dateTime

  end
end
