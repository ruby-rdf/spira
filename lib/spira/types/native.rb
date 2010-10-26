module Spira::Types

  ##
  # This type is a native type, doing no conversion to Ruby types.  The naked
  # RDF::Value (URI, Node, Literal, etc) will be used, and no deserialization
  # is done.
  #
  # @see Spira::Type
  class Native

    include Spira::Type

    def self.unserialize(value)
      value
    end

    def self.serialize(value)
      value
    end

  end
end
