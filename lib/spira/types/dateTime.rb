require 'bigdecimal'

module Spira::Types

  ##
  # A {Spira::Type} for integer values.  Values will be associated with the
  # `XSD.integer` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Integer`, `Integer`, or `XSD.integer`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class DateTime
    include Spira::Type

    def self.unserialize(value)
      object = value.object
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.dateTime)
    end

    register_alias XSD.dateTime

  end
end
