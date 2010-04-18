module Spira::Types
  class Float

    include Spira::Type

    def self.unserialize(value)
      value.object.to_f
    end

    def self.serialize(value)
      RDF::Literal.new(value.to_f, :datatype => XSD.double)
    end

    register_alias XSD.float
    register_alias XSD.double

  end
end
