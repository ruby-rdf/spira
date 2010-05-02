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
        if !self.type.nil? && attributes[:type]
          raise TypeError, "#{self} has an RDF type, #{self.type}, and cannot accept one as an argument."
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

      def inherited(child)
        child.instance_eval do
          include Spira::Resource
        end
        [:@properties, :@lists, :@base_uri, :@default_vocabulary, :@repository_name, :@type].each do |variable|
          value = instance_variable_get(variable).nil? ? nil : instance_variable_get(variable).dup
          child.instance_variable_set(variable, value)
        end
      end

    end
  end
end
