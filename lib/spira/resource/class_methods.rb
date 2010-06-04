module Spira
 module Resource

   ##
   # This module contains all class methods available to a declared Spira::Resource class.
   # {Spira::Resource} contains more information about Spira resources.
   #
   # @see Spira::Resource
   # @see Spira::Resource::InstanceMethods
   # @see Spira::Resource::DSL
    module ClassMethods

      ##
      # The current repository for this class
      # 
      # @param  [RDF::Repository] repo The repository
      # @return [Void]
      # @private
      def repository
        case @repository_name
          when nil
            Spira.repository(:default)
          else
            Spira.repository(@repository_name)
        end
      end

      ##
      # Create a new projection instance of this class for the given URI.  If a
      # class has a base_uri given, and the argument is not an `RDF::URI`, the
      # given identifier will be appended to the base URI.
      #
      # Spira does not have 'find' or 'create' functions.  As RDF identifiers
      # are globally unique, they all simply 'are'.
      #
      # On calling `for`, a new instance is created for the given URI.  The
      # first time access is attempted on a field, the repository will be
      # queried for existing attributes, which will be used for the given URI.
      # Underlying repositories are not accessed at the time of calling `for`.
      # 
      # A class with a base URI may still be projected for any URI, whether or
      # not it uses the given resource class' base URI.
      #
      # @raise [TypeError] if an RDF type is given in the attributes and one is
      # given in the attributes.  
      # @raise [ArgumentError] if a non-URI is given and the class does not
      # have a base URI.  
      # @overload for(uri, attributes = {})
      #   @param [RDF::URI] uri The URI to create an instance for
      #   @param [Hash{Symbol => Any}] attributes Initial attributes
      # @overload for(identifier, attributes = {})
      #   @param [Any] uri The identifier to append to the base URI for this class
      #   @param [Hash{Symbol => Any}] attributes Initial attributes
      # @return  [Spira::Resource] The newly created instance
      # @see http://rdf.rubyforge.org/RDF/URI.html
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
      # @param  [Any] Identifier
      # @return [RDF::URI]
      # @raise  [ArgumentError] If this class cannot create an identifier from the given string
      # @see http://rdf.rubyforge.org/RDF/URI.html
      def uri_for(identifier)
        case identifier
          when RDF::URI
            identifier
          else
            uri = RDF::URI.new(identifier.to_s)
            return uri if uri.absolute?
            raise ArgumentError, "Cannot create identifier for #{self} by String without base_uri; RDF::URI required" if self.base_uri.nil?
            separator = self.base_uri.to_s[-1,1] == "/" ? '' : '/'
            RDF::URI.new(self.base_uri.to_s + separator + identifier.to_s)
        end
      end


      ##
      # The number of URIs projectable as a given class in the repository.
      # This method is only valid for classes which declare a `type` with the
      # `type` method in the DSL.
      #
      # @raise  [TypeError] if the resource class does not have an RDF type declared
      # @return [Integer] the count
      # @see Spira::Resource::DSL
      def count
        raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." if @type.nil?
        result = repository.query(:predicate => RDF.type, :object => @type)
        result.count
      end

      ##
      # Returns true if the given property is a has_many property, false otherwise
      #
      # @return [true, false]
      def is_list?(property)
        @lists.has_key?(property)
      end

      ##
      # Handling inheritance
      #
      # @private
      def inherited(child)
        child.instance_eval do
          include Spira::Resource
        end
        # FIXME: This is clearly brittle and ugly.
        [:@base_uri, :@default_vocabulary, :@repository_name, :@type].each do |variable|
          value = instance_variable_get(variable).nil? ? nil : instance_variable_get(variable).dup
          child.instance_variable_set(variable, value)
        end
        [:@properties, :@lists, :@validators].each do |variable|
          if child.instance_variable_get(variable).nil?
            if instance_variable_get(variable).nil?
              child.instance_variable_set(variable, nil)
            else
              child.instance_variable_set(variable, instance_variable_get(variable).dup)
            end
          elsif !(instance_variable_get(variable).nil?)
            child.instance_variable_set(variable, instance_variable_get(variable).dup.merge(child.instance_variable_get(variable)))
          end
        end
      end

      ## 
      # Handling module inclusions
      #
      # @private
      def included(child)
        inherited(child)
      end

      ## 
      # The list of validation functions for this projection
      #
      # @return [Array<Symbol>]
      def validators
        @validators ||= []
      end

    end
  end
end
