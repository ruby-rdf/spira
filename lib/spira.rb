require 'rdf'

module Spira

  Thread.current[:spira] = {} 
  Thread.current[:spira][:repositories] = {}

  def add_repository(name, klass, *args)
    Thread.current[:spira][:repositories][name] = case klass
      when RDF::Repository
        klass
      else
        klass.new(*args)
     end
     if (name == :default) && Thread.current[:spira][:repositories][name].nil?
        warn "WARNING: Adding nil default repository"
     end
  end
  alias_method :add_repository!, :add_repository
  module_function :add_repository, :add_repository!

  def repository(name)
    Thread.current[:spira][:repositories][name]
  end
  module_function :repository

  autoload :Resource,         'spira/resource'

  class ValidationError < StandardError; end
end
