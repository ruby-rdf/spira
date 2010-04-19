require 'rdf/isomorphic'

module Spira
  module Resource
    module InstanceMethods 
  
      attr_reader :uri

      # Initialize a new instance of a spira resource.
      # The new instance can be instantiated with an opts[:statements] or opts[:attributes], but not both.
      def initialize(identifier, opts = {})
       
        @attributes = {}

        if identifier.is_a? RDF::URI
          @uri = identifier
        else
          if (self.class.base_uri)
            separator = self.class.base_uri.to_s[-1,1] == "/" ? '' : '/'
            @uri = RDF::URI.parse(self.class.base_uri.to_s + separator + identifier)
          else
            raise ArgumentError, "#{self.class} has no base URI configured, and can thus only be created using RDF::URIs (got #{identifier.inspect})"
          end
        end

        #  If we got statements, we are being loaded, not created
        if opts[:statements]
          # Set attributes for each statement corresponding to a predicate
          self.class.properties.each do |name, property|
            if self.class.is_list?(name)
              values = []
              statements = opts[:statements].query(:subject => @uri, :predicate => property[:predicate])
              unless statements.nil?
                statements.each do |statement|
                  values << self.class.build_value(statement,property[:type])
                end
              end
              attribute_set(name, values)
            else
              statement = opts[:statements].query(:subject => @uri, :predicate => property[:predicate]).first
              attribute_set(name, self.class.build_value(statement, property[:type]))
            end
          end
        else
          self.class.properties.each do |name, predicate|
            attribute_set(name, opts[name]) unless opts[name].nil?
          end

        end

        @original_attributes = @attributes.dup
        @original_attributes.each do | name, value |
          @original_attributes[name] = value.dup if value.is_a?(Array)
        end
      end
    
      def _destroy_attributes(attributes)
        repository = repository_for_attributes(attributes)
        self.class.repository.delete(*repository)
      end
  
      def destroy!
        _destroy_attributes(@attributes)
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
        repository = repository_for_attributes(@attributes)
        repository.insert(RDF::Statement.new(@uri, RDF.type, type)) unless type.nil?
        if block_given?
          repository.each(*args, &block)
        else
          ::Enumerable::Enumerator.new(self, :each)
        end
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
            #old = @repo.query(:subject => @uri, :predicate => predicate)
            #@repo.delete(*old.to_a) unless old.empty?
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
          # TODO: define behavior for equality on subclasses.  also subclasses.
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
