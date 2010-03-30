

module Spira

  @@repositories = {}

  def add_repository(name, klass, *args)
    @@repositories[name] = klass.new(*args)
  end
  module_function :add_repository

  def repository(name)
    @@repositories[name]
  end
  module_function :repository

  autoload :Resource, 'spira/resource'
  autoload :DSL,      'spira/dsl'
end
