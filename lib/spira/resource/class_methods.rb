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

      def for(identifier, attributes = {})
        if repository.nil?
          raise RuntimeError, "#{self} is configured to use #{@repository_name} as a repository, but was unable to find it." 
        end
        uri = uri_for(identifier)
        self.new(uri, attributes)
      end

      ##
      # Creates a URI based on a base_uri and string or URI
      #
      # @param [Any] Identifier
      # @return [RDF::URI]
      # @raises [ArgumentError] If this class cannot create an identifier from the given string
      def uri_for(identifier)
        uri = case identifier
          when RDF::URI
            identifier
          when String
            uri = RDF::URI.new(identifier)
            return uri if uri.absolute?
            raise ArgumentError, "Cannot create identifier for #{self} by String without base_uri; RDF::URI required" if self.base_uri.nil?
            separator = self.base_uri.to_s[-1,1] == "/" ? '' : '/'
            RDF::URI.new(self.base_uri.to_s + separator + identifier)
          else
            raise ArgumentError, "Cannot create an identifier for #{self} from #{identifier}, expected RDF::URI or String"
        end
      end

      def count
        raise TypeError, "Cannot count a #{self} without a reference type URI." if @type.nil?
        result = repository.query(:predicate => RDF.type, :object => @type)
        result.count
      end

      def is_list?(property)
        @lists.has_key?(property)
      end

    end
  end
end
