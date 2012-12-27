module Spira::Types

  ##
  # A {Spira::Type} for Float values.  Values will be associated with the
  # `XSD.double` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Float`, `Float`, `XSD.double`, or `XSD.float`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Float

    include Spira::Type

    def self.unserialize(value)
      value.object.to_f
    end

    def self.serialize(value)
      RDF::Literal.new(value.to_f, :datatype => RDF::XSD.double)
    end

    register_alias RDF::XSD.float
    register_alias RDF::XSD.double

  end
end
