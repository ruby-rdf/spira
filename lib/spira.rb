require 'rdf'
require 'rdf/isomorphic'

module RDF
  module Enumerable
    alias_method :==, :isomorphic_with?
  end
end


module Spira

  def self.included(child)
    child.extend ClassMethods
    child.instance_eval do
      class << self
        attr_accessor :base_uri, :repository, :properties
      end
      @properties = {}
    end
  end

  attr_reader :uri

  def initialize(identifier, attributes = {})
    @uri = RDF::URI.parse(self.class.base_uri + "/" + identifier)
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
 
    def source(klass, *args)
      self.repository = klass.new *args
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
