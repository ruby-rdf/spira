require 'rdf'
require 'rdf/isomorphic'

module Spira
 module Resource
  
    include RDF
  
    def self.included(child)
      child.extend ClassMethods
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
  
    module ClassMethods
  
      def repository=(repo)
        @repository = repo
      end

      def repository
        case
          when !@repository.nil?
            @repository
          when !@repository_name.nil?
            @repository = Spira.repository(@repository_name)
            if @repository.nil?
              raise RuntimeError, "#{self} is configured to use #{self.repository_name} as a repository, but was unable to find it."
            end
          else
            @repository = Spira.repository(:default)
            if @repository.nil? 
              raise RuntimeError, "#{self} has no configured repository and was unable to find a default repository."
            end
        end
        @repository
      end

      def default_source(name)
        @repository_name = name
        @repository = Spira.repository(name)
      end
  
      def base_path(string)
        self.base_uri = string
      end
  
      def property(name, predicate, type)
        @properties[name] = predicate
        name_equals = (name.to_s + "=").to_sym
        self.class_eval do
  
          define_method(name_equals) do |arg|
            old = @repo.query(:subject => @uri, :predicate => predicate)
            @repo.delete(old) unless old.empty?
            @repo.insert(RDF::Statement.new(@uri, predicate, arg))
          end
  
          define_method(name) do
            object = @repo.query(:subject => @uri, :predicate => predicate).first.object
            object = case
              when type == String
                object.object.to_s
              when type == Integer
                object.object
            end
          end
  
        end
      end
  
      def find(identifier)
        statements = self.repository.query(:subject => RDF::URI.parse(self.base_uri + "/" + identifier))
        if statements.empty?
          nil
        else
          self.new(identifier, :statements => statements) 
        end
      end
  
      def create(name, attributes = {})
        self.new(name, attributes)
      end
  
    end
  
  end
end
