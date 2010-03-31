module Spira
  module Resource
    module InstanceMethods 
  
      attr_reader :uri
    
      def initialize(identifier, attributes = {})
        
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
  
        @repo = RDF::Repository.new
        @repo.insert(*(attributes[:statements])) unless attributes[:statements].nil?
        @repo.insert(*[RDF::Statement.new(@uri, RDF.type, attributes[:type])]) if attributes[:type]
  
        self.class.properties.each do |name, predicate|
          send(((name.to_s)+"=").to_sym, attributes[name]) unless attributes[name].nil?
        end
        @original_repo = @repo.dup
        
      end
    
      def destroy!
        self.class.properties.each do | name, predicate |
          result = (self.class.repository.query(:subject => @uri, :predicate => predicate))
          self.class.repository.delete(*result) unless result.empty?
        end
      end
    
      def save!
        if respond_to?(:validate)
          errors.clear
          validate
          if errors.empty?
            _update!
          else
            raise (ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.join(';'))
          end
        else
          _update!
        end
      end

      def _update!
        destroy!
        self.class.repository.insert(*@repo)
        @original_repo = @repo.dup
      end
  
      def type
        self.class.type
      end
  
      def type=(type)
        raise TypeError, "Cannot reassign RDF.type for #{self}; consider appending to #types"
      end
  
      def inspect
        "<#{self.class}:#{self.object_id} uri: #{@uri}>"
      end
  
      def each(*args, &block)
        @repo.each(*args, &block)
      end
      include ::RDF::Enumerable, ::RDF::Queryable

      include Spira::Resource::Validations

    end  
  end
end
