module Spira::Types

  ##
  # A {Spira::Type} for Float values. Values will be associated with the
  # `XSD.float` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Float`, `Float`, or `XSD.float`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Float

    include Spira::Type

    def self.unserialize(value)
      value.object.to_f
    end

    def self.serialize(value)
      RDF::Literal.new(value.to_f, datatype: RDF::XSD.float)
    end

    register_alias RDF::XSD.float
  end
end
