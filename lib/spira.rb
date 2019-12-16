require "rdf"
require "rdf/ext/uri"
require "promise"
require "spira/exceptions"
require "spira/utils"
require "rdf/vocab"

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
  # The RDF::Repository used (reader)
  #
  # @return [RDF::Repository]
  # @see RDF::Repository
  def repository
    Thread.current[:repository]
  end
  module_function :repository

  ##
  # The RDF::Repository used (reader)
  #
  # @return [RDF::Repository]
  # @see RDF::Repository
  def repository=(repository)
    Thread.current[:repository] = repository
  end
  module_function :repository=

  ##
  # Clear the repository from Spira's knowledge.  Use it if you want, but
  # it's really here for testing.
  #
  # @return [Void]
  # @private
  def clear_repository!
    Spira.repository = nil
  end
  module_function :clear_repository!

  # Execute a block on a specific repository
  #
  # @param [RDF::Repository] repository the repository to work on
  # @param [Symbol] name the repository name
  # @yield the block with the instructions while using the repository
  def using_repository(repo)
    old_repository = Spira.repository
    Spira.repository = repo
    yield if block_given?
  ensure
    Spira.repository = old_repository
  end
  module_function :using_repository

  private

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
