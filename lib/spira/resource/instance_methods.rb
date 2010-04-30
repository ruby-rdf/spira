require 'rdf/isomorphic'

module Spira
  module Resource
    module InstanceMethods 
  
      attr_reader :uri

      # Initialize a new instance of a spira resource.
      # The new instance can be instantiated with an opts[:statements] or opts[:attributes], but not both.
      def initialize(identifier, opts = {})
        @uri = self.class.uri_for(identifier)
        reload(opts)
      end
  

      def reload(opts = {})
        @attributes = promise { reload_attributes }
        @original_attributes = promise { @attributes.force ; @original_attributes }
        self.class.properties.each do |name, predicate|
          attribute_set(name, opts[name]) unless opts[name].nil?
        end
      end

      ##
      # Load this instances attributes.  Overwrite loaded values with attributes in the given options.
      #
      # @param [Hash] opts
      # @return [Hash] @attributes
      def reload_attributes()
        if self.class.repository.nil?
          raise RuntimeError, "#{self} is configured to use #{@repository_name} as a repository, but was unable to find it." 
        end
        statements = self.class.repository.query(:subject => @uri)
        @attributes = {}

        unless statements.empty?
          # Set attributes for each statement corresponding to a predicate
          self.class.properties.each do |name, property|
            if self.class.is_list?(name)
              values = []
              collection = statements.query(:subject => @uri, :predicate => property[:predicate])
              unless collection.nil?
                collection.each do |statement|
                  values << self.class.build_value(statement,property[:type])
                end
              end
              attribute_set(name, values)
            else
              statement = statements.query(:subject => @uri, :predicate => property[:predicate]).first
              attribute_set(name, self.class.build_value(statement, property[:type]))
            end
          end
        end

        @original_attributes = {}
        @original_attributes = @attributes.dup
        @original_attributes.each do | name, value |
          @original_attributes[name] = value.dup if value.is_a?(Array)
        end

        @attributes
      end

      def _destroy_attributes(attributes, opts = {})
        repository = repository_for_attributes(attributes)
        repository.insert([@uri, RDF.type, self.class.type]) if (self.class.type && opts[:destroy_type])
        self.class.repository.delete(*repository)
      end
  
      def destroy!
        _destroy_attributes(@attributes, :destroy_type => true)
        reload
      end

      def save!
        if self.class.repository.nil?
          raise RuntimeError, "#{self} is configured to use #{@repository_name} as a repository, but was unable to find it." 
        end
        if respond_to?(:validate)
          errors.clear
          validate
          if errors.empty?
            _update!
          else
            raise(ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.join(';'))
          end
        else
          _update!
        end
      end

      def _update!
        _destroy_attributes(@original_attributes)
        self.class.repository.insert(*self)
        @original_attributes = @attributes.dup
      end
  
      def type
        self.class.type
      end
  
      def type=(type)
        raise TypeError, "Cannot reassign RDF.type for #{self}; consider appending to a has_many :types"
      end
  
      def inspect
        "<#{self.class}:#{self.object_id} uri: #{@uri}>"
      end
  
      def each(*args, &block)
        return Enumerable::Enumerator.new(self, :each) unless block_given?
        repository = repository_for_attributes(@attributes)
        repository.insert(RDF::Statement.new(@uri, RDF.type, type)) unless type.nil?
        repository.each(*args, &block)
      end

      def attribute_set(name, value)
        @attributes[name] = value
      end

      def attribute_get(name)
        case self.class.is_list?(name)
          when true
            @attributes[name] ||= []
          when false   
            @attributes[name]
        end
      end

      def repository_for_attributes(attributes)
        repo = RDF::Repository.new
        attributes.each do | name, attribute |
          if self.class.is_list?(name)
            new = []
            attribute.each do |value|
              value = self.class.build_rdf_value(value, self.class.properties[name][:type])
              new << RDF::Statement.new(@uri, self.class.properties[name][:predicate], value)
            end
            repo.insert(*new)
          else
            value = self.class.build_rdf_value(attribute, self.class.properties[name][:type])
            repo.insert(RDF::Statement.new(@uri, self.class.properties[name][:predicate], value))
          end
        end
        repo
      end

      def ==(other)
        case other
          # TODO: define behavior for equality on subclasses.  also implement subclasses.
          when self.class
            @uri == other.uri 
          when RDF::Enumerable
            self.isomorphic_with?(other)
          else
            false
        end
      end


      include ::RDF::Enumerable, ::RDF::Queryable

      include Spira::Resource::Validations

    end  
  end
end
