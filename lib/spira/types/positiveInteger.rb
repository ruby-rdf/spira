module Spira::Types

  ##
  # A {Spira::Type} for positive integer values.  Values will be associated with the
  # `XSD.positiveInteger` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::PositiveInteger`, `PositiveInteger`, or `XSD.positiveInteger`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class PositiveInteger

    include Spira::Type

    def self.unserialize(value)
      value.object.to_i
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.positiveInteger)
    end

    register_alias RDF::XSD.positiveInteger

  end
end
