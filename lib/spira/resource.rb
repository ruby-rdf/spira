module Spira
  module Resource
 
    autoload :DSL,              'spira/resource/dsl'
    autoload :ClassMethods,     'spira/resource/class_methods'
    autoload :InstanceMethods,  'spira/resource/instance_methods'
    autoload :Validations,      'spira/resource/validations'

    def self.included(child)
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
    
    # This lets including classes reference vocabularies without the RDF:: prefix
    include RDF
    include InstanceMethods

  end
end
