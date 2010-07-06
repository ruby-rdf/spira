module Spira::Types

  ##
  # This class does its best to serialize or unserialize RDF values into Ruby
  # values and vice versa using RDF.rb's built-in helpers for `RDF::Literal`s.
  # Its behavior is defined as 'What `RDF::Literal` does' for a given value.
  #
  # @see Spira::Type
  # @see http://rdf.rubyforge.org/RDF/Literal.html
  class Any

    include Spira::Type

    def self.unserialize(value)
      value.respond_to?(:to_uri) ? value.to_uri : value.object
    end

    def self.serialize(value)
      value.respond_to?(:to_uri) ? value.to_uri : RDF::Literal.new(value)
    end

  end
end
