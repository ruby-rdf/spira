module Spira::Types

  ##
  # A {Spira::Type} for Boolean values.  Values will be expressed as booleans
  # and packaged as `XSD.boolean` `RDF::Literal`s.
  #
  # A {Spira::Resource} property can reference this type as
  # `Spira::Types::Boolean`, `Boolean`, or `XSD.boolean`.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Boolean

    include Spira::Type

    def self.unserialize(value)
      value.object == true
    end

    def self.serialize(value)
      if value
        RDF::Literal.new(true, :datatype => XSD.boolean)
      else 
        RDF::Literal.new(false, :datatype => XSD.boolean)
      end
    end

    register_alias XSD.boolean

  end
end
