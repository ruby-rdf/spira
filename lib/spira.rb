require "rdf"
require "rdf/ext/uri"
require "promise"
require "spira/exceptions"

##
# Spira is a framework for building projections of RDF data into Ruby classes.
# It is built on top of RDF.rb.
#
# @see http://rdf.rubyforge.org
# @see http://github.com/bhuga/spira
# @see Spira::Resource
module Spira

  autoload :Base,             'spira/base'
  autoload :Type,             'spira/type'
  autoload :Types,            'spira/types'
  autoload :VERSION,          'spira/version'

  # Marker for whether or not a field has been set or not;
  # distinguishes nil and unset.
  NOT_SET = ::Object.new.freeze

  ##
  # The list of all property types available for Spira resources
  #
  # @see Spira::Types
  # @return [Hash{Symbol => Spira::Type}]
  def types
    @types ||= {}
  end
  module_function :types

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
    repositories[name] =
      case klass
      when Class
        promise { klass.new(*args) }
      else
        klass
      end
    if (name == :default) && repository(name).nil?
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
    @repositories = {}
  end
  module_function :clear_repositories!


  private

  ##
  # The list of repositories available for Spira resources
  #
  # @see http://rdf.rubyforge.org/RDF/Repository.html
  # @return [Hash{Symbol => RDF::Repository}]
  def repositories
    @repositories ||= {}
  end
  module_function :repositories

  ##
  # Alias a property type to another.  This allows a range of options to be
  # specified for a property type which all reference one Spira::Type
  #
  # @param [Any] new The new symbol or reference
  # @param [Any] original The type the new symbol should refer to
  # @return [Void]
  def type_alias(new, original)
    types[new] = original
  end
  module_function :type_alias
end
