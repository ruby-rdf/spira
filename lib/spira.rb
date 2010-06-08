require 'rdf'
require 'spira/exceptions'

##
# Spira is a framework for building projections of RDF data into Ruby classes.
# It is built on top of RDF.rb.
#
# @see http://rdf.rubyforge.org
# @see http://github.com/bhuga/spira
# @see Spira::Resource
module Spira

  ##
  # The list of repositories available for Spira resources
  #
  # @see http://rdf.rubyforge.org/RDF/Repository.html
  # @return [Hash{Symbol => RDF::Repository}]
  # @private
  def repositories
    settings[:repositories] ||= {}
  end
  module_function :repositories

  ##
  # The list of all property types available for Spira resources
  # 
  # @see Spira::Types
  # @return [Hash{Symbol => Spira::Type}]
  def types
    settings[:types] ||= {}
  end
  module_function :types

  ##
  # A thread-local hash for storing settings.  Used by Resource classes.
  #
  # @see Spira::Resource
  # @see Spira.repositories
  # @see Spira.types
  def settings
    Thread.current[:spira] ||= {}
  end
  module_function :settings

  ##
  # Add a repository to Spira's list of repositories.
  #
  # @overload add_repository(name, repo)
  #     @param [Symbol] name The name of this repository
  #     @param [RDF::Repository] repo An RDF::Repository
  # @overload add_repository(name, klass, *args)
  #     @param [Symbol] name The name of this repository
  #     @param [RDF::Repository, Class] repo A Class that inherits from RDF::Repository
  #     @param [*Object] The list of arguments to instantiate the class
  # @example Adding an ntriples file as a repository
  #     Spira.add_repository(:default, RDF::Repository.load('http://datagraph.org/jhacker/foaf.nt'))
  # @example Adding an empty repository to be instantiated on use
  #     Spira.add_repository(:default, RDF::Repository)
  # @return [Void]
  # @see RDF::Repository
  def add_repository(name, klass, *args)
    repositories[name] = case klass
      when RDF::Repository
        klass
      when Class
        klass.new(*args)
      else
        raise ArgumentError, "Could not add repository #{klass} as #{name}; expected an RDF::Repository or class name"
     end
     if (name == :default) && settings[:repositories][name].nil?
        warn "WARNING: Adding nil default repository"
     end
  end
  alias_method :add_repository!, :add_repository
  module_function :add_repository, :add_repository!

  ##
  # The RDF::Repository for the named repository
  #
  # @param [Symbol] name The name of the repository
  # @return [RDF::Repository]
  # @see RDF::Repository
  def repository(name)
    repositories[name]
  end
  module_function :repository

  ##
  # Clear all repositories from Spira's knowledge.  Use it if you want, but
  # it's really here for testing.
  #
  # @return [Void]
  # @private
  def clear_repositories!
    settings[:repositories] = {}
  end
  module_function :clear_repositories!

  ##
  # Alias a property type to another.  This allows a range of options to be
  # specified for a property type which all reference one Spira::Type
  #
  # @param [Any] new The new symbol or reference
  # @param [Any] original The type the new symbol should refer to
  # @return [Void]
  # @private
  def type_alias(new, original)
    types[new] = original 
  end
  module_function :type_alias

  autoload :Resource,         'spira/resource'
  autoload :Base,             'spira/base'
  autoload :Type,             'spira/type'
  autoload :Types,            'spira/types'
  autoload :Errors,           'spira/errors'
  autoload :VERSION,          'spira/version'

end

module RDF
  class URI
    ##
    # Create a projection of this URI as the given Spira::Resource class.
    # Equivalent to `klass.for(self, *args)`
    #
    # @example Instantiating a URI as a Spira Resource
    #     RDF::URI('http://example.org/person/bob').as(Person)
    # @param [Class] klass
    # @param [*Any] args Any arguments to pass to klass.for
    # @return [Klass] An instance of klass
    def as(klass, *args)
      raise ArgumentError, "#{klass} is not a Spira resource" unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Resource)
      klass.for(self, *args)
    end
  end

  class Node
    ##
    # Create a projection of this Node as the given Spira::Resource class.
    # Equivalent to `klass.for(self, *args)`
    #
    # @example Instantiating a blank node as a Spira Resource
    #     RDF::Node.new.as(Person)
    # @param [Class] klass
    # @param [*Any] args Any arguments to pass to klass.for
    # @return [Klass] An instance of klass
    def as(klass, *args)
      raise ArgumentError, "#{klass} is not a Spira resource" unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Resource)
      klass.for(self, *args)
    end
  end
end
