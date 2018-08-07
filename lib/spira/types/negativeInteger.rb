module Spira::Types

  ##
  # A {Spira::Type} for negative integer values.  Values will be associated with the
  # `XSD.negativeInteger` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::NegativeInteger`, `NegativeInteger`, or `XSD.negativeInteger`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class NegativeInteger

    include Spira::Type

    def self.unserialize(value)
      value.object.to_i
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.negativeInteger)
    end

    register_alias RDF::XSD.negativeInteger

  end
end
