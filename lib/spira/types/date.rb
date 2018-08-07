module Spira::Types

  ##
  # A {Spira::Type} for dates.  Values will be associated with the
  # `XSD.date` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Date`, `Date`, or `XSD.date`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Date
    include Spira::Type

    def self.unserialize(value)
      object = value.object
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.date)
    end

    register_alias RDF::XSD.date

  end
end
