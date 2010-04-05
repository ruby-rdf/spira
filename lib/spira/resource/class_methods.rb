module Spira
 module Resource

   # This module contains all class methods available to a Spira::Resource class
   #
   #
    module ClassMethods
      def repository=(repo)
        @repository = repo
      end

      def repository
        case @repository_name
          when nil
            Spira.repository(:default)
          else
            Spira.repository(@repository_name)
        end
      end

      def oldrepo
        case
          #when !@repository.nil?
          #  @repository
          when !@repository_name.nil?
            Spira.repository(@repository_name) || raise(RuntimeError, "#{self} is configured to use #{@repository_name} as a repository, but was unable to find it.")
            #@repository = Spira.repository(@repository_name)
            #if @repository.nil?
            #  raise RuntimeError, "#{self} is configured to use #{@repository_name} as a repository, but was unable to find it."
            #end
            #@repository
          else
            @repository = Spira.repository(:default)
            if @repository.nil? 
              raise RuntimeError, "#{self} has no configured repository and was unable to find a default repository."
            end
            @repository
        end
        #@repository
      end

      def find(identifier)
        if repository.nil?
          raise RuntimeError, "#{self} is configured to use #{@repository_name} as a repository, but was unable to find it." 
        end
        uri = case identifier
          when RDF::URI
            identifier
          when String
            raise ArgumentError, "Cannot find #{self} by String without base_uri; RDF::URI required" if self.base_uri.nil?
            separator = self.base_uri.to_s[-1,1] == "/" ? '' : '/'
            RDF::URI.parse(self.base_uri.to_s + separator + identifier)
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
        unless @type.nil?
          if attributes[:type]
            raise TypeError, "Cannot assign type to new instance of #{self}; this class is associated with #{@type}"
          end
          attributes[:type] = @type
        end
        resource = self.new(name, attributes)
      end

      def is_list?(property)
        @lists.has_key?(property)
      end

    end
  end
end
