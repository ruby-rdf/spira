module Spira
 module Resource

   # This module contains all user-exposed methods for use in building a model class.
   # It is used to extend classes that include Spira::Resource.
   # @see a little bit of magic in Spira::Resource#included as well--some
   # tricks need class_eval before this module is included.
   #
    module DSL  
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
              raise RuntimeError, "#{self} is configured to use #{@repository_name} as a repository, but was unable to find it."
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
  
      def default_base_uri(string)
        @base_uri = string
      end
  
      def property(name, predicate, type)
        @properties[name] = predicate
        name_equals = (name.to_s + "=").to_sym
        self.class_eval do
  
          define_method(name_equals) do |arg|
            old = @repo.query(:subject => @uri, :predicate => predicate)
            @repo.delete(*old.to_a) unless old.empty?
            arg = arg.uri if arg.class.ancestors.include?(Spira::Resource)
            @repo.insert(RDF::Statement.new(@uri, predicate, arg))
          end
  
          define_method(name) do
            statement = @repo.query(:subject => @uri, :predicate => predicate).first
            value = case
              when statement.nil?
                nil
              when type == String
                statement.object.object.to_s
              when type == Integer
                statement.object.object
              when type.is_a?(Symbol)
                klass = Kernel.const_get(type.to_s.capitalize)
                raise TypeError, "#{klass} is not a Spira Resource (referenced as #{type} by #{self}" unless klass.ancestors.include? Spira::Resource
                klass.find statement.object
            end
          end
  
        end
      end

      def has_many(name, predicate, type)
        @properties[name] = predicate
        name_equals = (name.to_s + "=").to_sym
        self.class_eval do

          define_method(name_equals) do |arg|
            old = @repo.query(:subject => @uri, :predicate => predicate)
            @repo.delete(*old.to_a) unless old.empty?
            new = []
            arg.each do |value|
              value = value.uri if value.class.ancestors.include?(Spira::Resource)
              new << RDF::Statement.new(@uri, predicate, value)
            end
            @repo.insert(*new)
          end

          define_method(name) do
            values = []
            statements = @repo.query(:subject => @uri, :predicate => predicate)
            statements.each do |statement|
              value = case
                when type == String
                  statement.object.object.to_s
                when type == Integer
                  statement.object.object
                when type.is_a?(Symbol)
                  klass = Kernel.const_get(type.to_s.capitalize)
                  raise TypeError, "#{klass} is not a Spira Resource (referenced as #{type} by #{self}" unless klass.ancestors.include? Spira::Resource
                  klass.find(statement.object) || klass.create(statement.object)
              end
              values << value
            end
            values
          end
        end
      end



      def type(uri = nil)
        unless uri.nil?
          @type = case uri
            when RDF::URI
              uri
            else
              raise TypeError, "Cannot assign type #{uri} (of type #{uri.class}) to #{self}, expected RDF::URI"
          end
        end
        @type
      end

      def find(identifier)
        uri = case identifier
          when RDF::URI
            identifier
          when String
            raise ArgumentError, "Cannot find #{self} by String without base_uri; RDF::URI required" if self.base_uri.nil?
            RDF::URI.parse(self.base_uri.to_s + "/" + identifier)
          else
            raise ArgumentError, "Cannot instantiate #{self} from #{identifier}, expected RDF::URI or String"
        end
        statements = self.repository.query(:subject => uri)
        if statements.empty?
          nil
        else
          self.new(identifier, :statements => statements) 
        end
      end
 
      def count
        raise TypeError, "Cannot count a #{self} without a reference type URI." if @type.nil?
        result = repository.query(:predicate => RDF.type, :object => @type)
        result.count
      end

      def create(name, attributes = {})
        # TODO: validate attributes
        if !@type.nil?
          if attributes[:type]
            raise TypeError, "Cannot assign type to new instance of #{self}; type must be #{@type}"
          end
          attributes[:type] = @type
        end
        resource = self.new(name, attributes)
      end
  
    end
  end
end
