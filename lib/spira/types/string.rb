module Spira::Types

  ##
  # A {Spira::Type} for string values.  Values will be associated with the
  # `XSD.string` type with no language code.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::String`, `String`, or `XSD.string`.
  #
  # @see Spira::Type
  # @see https://www.rubydoc.info/github/ruby-rdf/rdf/RDF/Literal.html
  class String

    include Spira::Type

    def self.unserialize(value)
      value.object.to_s
    end

    def self.serialize(value)
      RDF::Literal.new(value.to_s)
    end

    register_alias RDF::XSD.string

  end
end
