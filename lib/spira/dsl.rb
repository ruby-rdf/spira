module Spira
  ##
  # This module consists of Spira::Base class methods which correspond to
  # the Spira resource class declaration DSL.  See {Spira::Base} for more
  # information.
  module DSL

    ##
    # A symbol name for the repository this class is currently using.
    attr_reader :repository_name

    ##
    # The name of the default repository to use for this class.  This
    # repository will be queried and written to instead of the :default
    # repository.
    #
    # @param  [Symbol] name
    # @return [Void]
    def default_source(name)
      @repository_name = name
    end

    ##
    # The base URI for this class.  Attempts to create instances for non-URI
    # objects will be appended to this base URI.
    #
    # @param  [String, RDF::URI] base uri
    # @return [Void]
    def base_uri(uri = nil)
      @base_uri = uri unless uri.nil?
      @base_uri
    end

    ##
    # The default vocabulary for this class.  Setting a default vocabulary
    # will allow properties to be defined without a `:predicate` option.
    # Predicates will instead be created by appending the property name to
    # the given string.
    #
    # @param  [String, RDF::URI] base uri
    # @return [Void]
    def default_vocabulary(uri)
      @default_vocabulary = uri
    end

  end
end
