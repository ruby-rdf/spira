module Spira::Types

  ##
  # A {Spira::Type} for nonpositive integer values.  Values will be associated with the
  # `XSD.nonPositiveInteger` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::NonPositiveInteger`, `NonPositiveInteger`, or `XSD.nonPositiveInteger`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class NonPositiveInteger

    include Spira::Type

    def self.unserialize(value)
      value.object.to_i
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.nonPositiveInteger)
    end

    register_alias RDF::XSD.nonPositiveInteger

  end
end
