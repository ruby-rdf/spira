module Spira::Types

  ##
  # A {Spira::Type} for integer values.  Values will be associated with the
  # `XSD.int` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Int`, `Int`, or `XSD.int`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Int

    include Spira::Type

    def self.unserialize(value)
      value.object.to_i
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.int)
    end

    register_alias RDF::XSD.int

  end
end
