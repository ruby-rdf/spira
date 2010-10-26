module Spira

  ##
  # Spira::Resource is the main interface to Spira.  Classes and modules
  # include Spira::Resource to create projections of RDF data as a class.  For
  # an overview, see the {file:README}.
  #
  # Projections are a mapping of RDF predicates to fields.
  #
  #     class Person
  #       include Spira::Resource
  #
  #       property :name, :predicate => FOAF.name
  #       property :age, :predicate => FOAF.age, :type => Integer
  #     end
  #
  #     RDF::URI('http://example.org/people/bob').as(Person) #=> <#Person @uri=http://example.org/people/bob>
  #
  # Spira resources include the RDF namespace, and can thus reference all of
  # the default RDF.rb vocabularies without the RDF:: prefix:
  #
  #     property :name, :predicate => FOAF.name
  #
  # The Spira::Resource documentation is broken into several parts, vaguely
  # related by functionality:
  #  * {Spira::Resource::DSL} contains methods used during the declaration of a class or module
  #  * {Spira::Resource::ClassMethods} contains class methods for use by declared classes
  #  * {Spira::Resource::InstanceMethods} contains methods for use by instances of Spira resource classes
  #  * {Spira::Resource::Validations} contains some default validation functions
  #
  # @see Spira::Resource::DSL
  # @see Spira::Resource::ClassMethods
  # @see Spira::Resource::InstanceMethods
  # @see Spira::Resource::Validations
  module Resource
 
    autoload :DSL,              'spira/resource/dsl'
    autoload :ClassMethods,     'spira/resource/class_methods'
    autoload :InstanceMethods,  'spira/resource/instance_methods'
    autoload :Validations,      'spira/resource/validations'

    ##
    # When a child class includes Spira::Resource, this does the magic to make
    # it a Spira resource.
    #
    # @private
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
    include Spira::Types
    include ::RDF
    include InstanceMethods

  end
end
