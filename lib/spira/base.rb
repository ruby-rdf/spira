module Spira

  ##
  # Spira::Base does nothing but include Spira::Resource, if it's more your
  # style to do inheritance than module inclusion.
  #
  # @see Spira::Resource
  class Base
    include Spira::Resource
  end
end
