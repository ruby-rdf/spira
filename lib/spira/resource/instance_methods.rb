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

        @repo = RDF::Repository.new
        @repo.insert(*(opts[:statements])) unless opts[:statements].nil?
        @repo.insert(*[RDF::Statement.new(@uri, RDF.type, opts[:type])]) if opts[:type]

        #  If we got statements, we are being loaded, not created
        if opts[:statements]
          # Set attributes for each statement corresponding to a predicate
          self.class.properties.each do |name, predicate|
            if self.class.is_list?(name)
              values = []
              statements = @repo.query(:subject => @uri, :predicate => predicate)
              unless statements.nil?
                statements.each do |statement|
                  values << self.class.build_value(statement,self.class.properties[name])
                end
              end
              attribute_set(name, values)
            else
              statement = @repo.query(:subject => @uri, :predicate => predicate)
              unless statement.nil?
                attribute_set(name, self.class.build_value(statement.first, self.class.properties[name]))
              end
            end
          end
        else
          self.class.properties.each do |name, predicate|
            attribute_set(name, opts[name]) unless opts[name].nil?
          end
        end


        @repo = RDF::Repository.new
        @repo.insert(*(opts[:statements])) unless opts[:statements].nil?
        @repo.insert(*[RDF::Statement.new(@uri, RDF.type, opts[:type])]) if opts[:type]
  
        self.class.properties.each do |name, predicate|
          send(((name.to_s)+"=").to_sym, opts[name]) unless opts[name].nil?
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
            raise(ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.join(';'))
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

      def attribute_set(name, value)
        @attributes[name] = value
      end

      def attribute_get(name)
        @attributes[name]
      end

      include ::RDF::Enumerable, ::RDF::Queryable

      include Spira::Resource::Validations

    end  
  end
end
