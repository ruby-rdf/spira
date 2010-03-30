

module Spira

  Thread.current[:spira] = {} 
  Thread.current[:spira][:repositories] = {}

  def add_repository(name, klass, *args)
    Thread.current[:spira][:repositories][name] = klass.new(*args)
  end
  alias_method :add_repository!, :add_repository
  module_function :add_repository, :add_repository!

  def repository(name)
    Thread.current[:spira][:repositories][name]
  end
  module_function :repository

  autoload :Resource, 'spira/resource'
  autoload :DSL,      'spira/dsl'
end
