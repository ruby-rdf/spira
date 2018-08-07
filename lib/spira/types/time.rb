module Spira::Types

  ##
  # A {Spira::Type} for times.  Values will be associated with the
  # `XSD.time` type.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Time`, `Time`, or `XSD.time`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Time
    include Spira::Type

    def self.unserialize(value)
      object = value.object.to_time
    end

    def self.serialize(value)
      RDF::Literal.new(value, :datatype => XSD.time)
    end

    register_alias RDF::XSD.time

  end
end
