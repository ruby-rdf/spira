module Spira

  ##
  # Spira::Types is a set of default Spira::Type classes.
  #
  # @see Spira::Type
  # @see Spira::Types::Int
  # @see Spira::Types::Integer  
  # @see Spira::Types::Boolean
  # @see Spira::Types::String
  # @see Spira::Types::Date
  # @see Spira::Types::DateTime
  # @see Spira::Types::Float
  # @see Spira::Types::Any
  module Types

    # No autoloading here--the associations to XSD types are made by the
    # classes themselves, so we need to require them or XSD types
    # will show up as not found.
    
    Dir.glob(File.join(File.dirname(__FILE__), 'types', '*.rb')).each { |file| require file }

  end
end
