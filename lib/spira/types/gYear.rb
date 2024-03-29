module Spira::Types

  ##
  # A {Spira::Type} for gYear.  Values will be associated with the
  # `XSD.gYear` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::GYear`, `GYear`, or `XSD.gYear`.
  #
  # @see Spira::Type
  # @see https://ruby-rdf.github.io/rdf/RDF/Literal.html
  class GYear
    include Spira::Type

    def self.unserialize(value)
      object = value.object.to_i
    end

    def self.serialize(value)
      RDF::Literal.new(value, datatype: XSD.gYear)
    end

    register_alias RDF::XSD.gYear

  end
end
