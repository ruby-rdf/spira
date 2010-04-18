require 'rdf'

module Spira


  def repositories
    settings[:repositories] ||= {}
  end
  module_function :repositories

  def types
    settings[:types] ||= {}
  end
  module_function :types

  def settings
    Thread.current[:spira] ||= {}
  end
  module_function :settings

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

  def repository(name)
    repositories[name]
  end
  module_function :repository

  def type_alias(new, original)
    types[new] = original 
  end
  module_function :type_alias

  autoload :Resource,         'spira/resource'
  autoload :Type,             'spira/type'
  autoload :Types,            'spira/types'

  class ValidationError < StandardError; end
end
