module Spira

  ##
  # Spira::Types is a set of default Spira::Type classes.
  #
  # @see Spira::Type
  # @see Spira::Types::Integer
  # @see Spira::Types::Boolean
  # @see Spira::Types::String
  # @see Spira::Types::Float
  # @see Spira::Types::Any
  module Types

    # No autoloading here--the associations to XSD types are made by the
    # classes themselves, so we need to explicitly require them or XSD types
    # will show up as not found.
    require 'spira/types/integer'
    require 'spira/types/boolean'
    require 'spira/types/any'
    require 'spira/types/string'
    require 'spira/types/float'


  end
end
