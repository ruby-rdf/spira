module Spira::Types
  class String

    include Spira::Type

    def self.unserialize(value)
      value.object.to_s
    end

    def self.serialize(value)
      RDF::Literal.new(value.to_s)
    end

    register_alias XSD.string

  end
end
