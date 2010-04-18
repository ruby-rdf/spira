module Spira::Types
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
