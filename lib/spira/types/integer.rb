module Spira::Types
  class Integer

    include Spira::Type

    def self.unserialize(value)
      value.object
    end

    def self.serialize(value)
      RDF::Literal.new(value)
    end

    register_alias XSD.integer

  end
end
