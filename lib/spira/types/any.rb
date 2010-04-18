module Spira::Types
  class Any

    include Spira::Type

    def self.unserialize(value)
      value.object
    end

    def self.serialize(value)
      RDF::Literal.new(value)
    end

  end
end
