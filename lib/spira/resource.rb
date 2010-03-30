require 'rdf'
require 'rdf/isomorphic'

module Spira
 module Resource
  
    include RDF
  
    def self.included(child)
      child.extend DSL
      child.instance_eval do
        class << self
          attr_accessor :base_uri, :properties
        end
        @properties = {}
      end
    end
  
    attr_reader :uri
  
    def initialize(identifier, attributes = {})
      if identifier.is_a? URI
        @uri = identifier
      else
        if (self.class.base_uri)
          @uri = URI.parse(self.class.base_uri + "/" + identifier)
        else
          raise ArgumentError, "#{self.class} has no base URI configured, and can thus only be created using RDF::URIs (got #{identifier.inspect})"
        end
      end

      @repo = RDF::Repository.new
      @repo.insert(*(attributes[:statements])) unless attributes[:statements].nil?
      @original_repo = @repo.dup
    end
  
    def destroy!
      self.class.properties.each do | name, predicate |
        result = (self.class.repository.query(:subject => @uri, :predicate => predicate))
        self.class.repository.delete(*result) unless result.empty?
      end
    end
  
    def save!
      destroy!
      self.class.repository.insert(*@repo)
    end
  
    def each(*args, &block)
      @repo.each(*args, &block)
    end
    include ::RDF::Enumerable, ::RDF::Queryable
  
  end
end
