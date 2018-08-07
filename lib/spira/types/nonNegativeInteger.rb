module Spira::Types

  ##
  # A {Spira::Type} for nonnegative integer values.  Values will be associated with the
  # `XSD.nonNegativeInteger` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::NonNegativeInteger`, `NonNegativeInteger`, or `XSD.nonNegativeInteger`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class NonNegativeInteger

    include Spira::Type

    def self.unserialize(value)
      value.object.to_i
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.nonNegativeInteger)
    end

    register_alias RDF::XSD.nonNegativeInteger

  end
end
