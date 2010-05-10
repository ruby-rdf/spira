module Spira
  module Resource
 
    autoload :DSL,              'spira/resource/dsl'
    autoload :ClassMethods,     'spira/resource/class_methods'
    autoload :InstanceMethods,  'spira/resource/instance_methods'
    autoload :Validations,      'spira/resource/validations'

    def self.included(child)
      # Don't do inclusion work twice.  Checking for the properties accessor is
      # a proxy for a proper check to see if this is a resource already.  Ruby
      # has already extended the child class' ancestors to include
      # Spira::Resource by the time we get here.
      # FIXME: Find a 'more correct' check.
      unless child.respond_to?(:properties)
        child.extend DSL
        child.extend ClassMethods
        child.instance_eval do
          class << self
            attr_accessor :properties, :lists
          end
          @properties = {}
          @lists      = {}
        end
      end
    end
    
    # This lets including classes reference vocabularies without the RDF:: prefix
    include RDF
    include Spira::Types
    include InstanceMethods

  end
end
