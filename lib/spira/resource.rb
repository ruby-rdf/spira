module Spira
  module Resource
 
    autoload :DSL,              'spira/resource/dsl'
    autoload :ClassMethods,     'spira/resource/class_methods'
    autoload :InstanceMethods,  'spira/resource/instance_methods'

    def self.included(child)
      child.extend DSL
      child.instance_eval do
        class << self
          attr_accessor :base_uri, :properties
        end
        @properties = {}
      end
    end
    
    # This lets including classes reference vocabularies without the RDF:: prefix
    include RDF
    include InstanceMethods

  end
end
