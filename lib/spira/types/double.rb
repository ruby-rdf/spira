module Spira::Types

  ##
  # A {Spira::Type} for Double values.  Values will be associated with the
  # `XSD.double` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Double`, `Double`, or `XSD.double`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Double

    include Spira::Type

    def self.unserialize(value)
      value.object.to_f
    end

    def self.serialize(value)
      RDF::Literal.new(value.to_f, :datatype => RDF::XSD.double)
    end

    register_alias RDF::XSD.double

  end
end
