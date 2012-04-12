module Spira

  ##
  # Spira::Type can be included by classes to create new property types for
  # Spira.  These types are responsible for serialization a Ruby value into an
  # `RDF::Value`, and deserialization of an `RDF::Value` into a Ruby value.
  #
  # A simple example:
  #
  #     class Integer
  #
  #       include Spira::Type
  #
  #       def self.unserialize(value)
  #         value.object
  #       end
  #
  #       def self.serialize(value)
  #         RDF::Literal.new(value)
  #       end
  #
  #       register_alias XSD.integer
  #     end
  #
  # This example will serialize and deserialize integers.  It's included with
  # Spira by default.  It allows either of the following forms to declare an
  # integer property on a Spira resource:
  #
  #     property :age, :predicate => FOAF.age, :type => Integer
  #     property :age, :predicate => FOAF.age, :type => XSD.integer
  #
  # `Spira::Type`s include the RDF namespace and thus have all of the base RDF
  # vocabularies available to them without the `RDF::` prefix.
  #
  # @see http://rdf.rubyforge.org/RDF/Value.html
  # @see Spira::Resource
  module Type

    ##
    # Make the DSL available to a child class.
    #
    # @private
    def self.included(child)
      child.extend(ClassMethods)
      Spira.type_alias(child,child)
    end

    include RDF

    module ClassMethods

      ##
      # Register an alias that this type can be referred to as, such as an RDF
      # URI.  The alias can be any object, symbol, or constant.
      #
      # @param [Any] identifier The new alias in property declarations for this class
      # @return [Void]
      def register_alias(any)
        Spira.type_alias(any, self)
      end

      ##
      # Serialize a given value to RDF.
      #
      # @param [Any] value The Ruby value to be serialized
      # @return [RDF::Value] The RDF form of this value
      def serialize(value)
        value
      end

      ##
      # Unserialize a given RDF value to Ruby
      #
      # @param [RDF::Value] value The RDF form of this value
      # @return [Any] The Ruby form of this value
      def unserialize(value)
        value
      end
    end

  end
end
