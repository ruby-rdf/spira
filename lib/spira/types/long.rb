module Spira::Types

  ##
  # A {Spira::Type} for integer values.  Values will be associated with the
  # `XSD.long` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Long`, `Long`, or `XSD.long`.
  #
  # @see Spira::Type
  # @see https://ruby-rdf.github.io/rdf/RDF/Literal.html
  class Long

    include Spira::Type

    def self.unserialize(value)
      value.object.to_i
    end

    def self.serialize(value)
      RDF::Literal.new(value, datatype: XSD.long)
    end

    register_alias RDF::XSD.long

  end
end
