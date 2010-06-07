require 'rdf/isomorphic'

module Spira
  module Resource

    ##
    # This module contains instance methods for Spira resources.  See
    # {Spira::Resource} for more information.
    #
    # @see Spira::Resource
    # @see Spira::Resource::ClassMethods
    # @see Spira::Resource::DSL
    # @see Spira::Resource::Validations
    module InstanceMethods 
 
      ##
      # This instance's URI.
      #
      # @return [RDF::URI]
      attr_reader :subject

      ## 
      # Initialize a new Spira::Resource instance of this resource class.  This
      # method should not be called directly, use
      # {Spira::Resource::ClassMethods#for} instead.
      #
      # @param [RDF::URI, RDF::Node] identifier The URI or URI fragment for this instance
      # @param [Hash] opts Default attributes for this instance
      # @see Spira::Resource::ClassMethods#for
      def initialize(identifier, opts = {})
        @subject = identifier
        reload(opts)
      end
  
      ##
      # Reload all attributes for this instance, overwriting or setting
      # defaults with the given opts.  This resource will block if the
      # underlying repository blocks the next time it accesses attributes.
      #
      # @param   [Hash{Symbol => Any}] opts
      # @option opts [Symbol] :any A property name.  Sets the given property to the given value.
      def reload(opts = {})
        @attributes = promise { reload_attributes }
        @original_attributes = promise { @attributes.force ; @original_attributes }
        self.class.properties.each do |name, predicate|
          attribute_set(name, opts[name]) unless opts[name].nil?
        end
      end

      ##
      # Load this instance's attributes.  Overwrite loaded values with attributes in the given options.
      #
      # @param [Hash] opts
      # @return [Hash] @attributes
      # @private
      def reload_attributes()
        statements = self.class.repository_or_fail.query(:subject => @subject)
        @attributes = {}

        unless statements.empty?
          # Set attributes for each statement corresponding to a predicate
          self.class.properties.each do |name, property|
            if self.class.is_list?(name)
              # FIXME: This should not be an Array, but a Set.  However, a set
              # must compare its values to see if they already exist.  This
              # means any referenced relations will check their attributes and
              # execute the promises to load those classes.  Need an identity
              # map of some sort to fix that.
              values = []
              collection = statements.query(:subject => @subject, :predicate => property[:predicate])
              unless collection.nil?
                collection.each do |statement|
                  values << self.class.build_value(statement,property[:type])
                end
              end
              attribute_set(name, values)
            else
              statement = statements.query(:subject => @subject, :predicate => property[:predicate]).first
              attribute_set(name, self.class.build_value(statement, property[:type]))
            end
          end
        end

        # We need to load and save the original attributes so we can remove
        # them from the repository on save, since RDF will happily let us add
        # as many triples for a subject and predicate as we want.
        @original_attributes = {}
        @original_attributes = @attributes.dup
        @original_attributes.each do | name, value |
          @original_attributes[name] = value.dup if value.is_a?(Array)
        end

        @attributes
      end

      ##
      # Remove the given attributes from the repository
      #
      # @param [Hash] attributes The hash of attributes to delete
      # @param [Hash{Symbol => Any}] opts Options for deletion
      # @option opts [true] :destroy_type Destroys the `RDF.type` statement associated with this class as well
      # @private
      def _destroy_attributes(attributes, opts = {})
        repository = repository_for_attributes(attributes)
        repository.insert([@subject, RDF.type, self.class.type]) if (self.class.type && opts[:destroy_type])
        self.class.repository_or_fail.delete(*repository)
      end
 
      ##
      # Remove this instance from the repository.  Will not delete statements
      # not associated with this model.
      #
      # @return [true, false] Whether or not the destroy was successful
      def destroy!
        _destroy_attributes(@attributes, :destroy_type => true)
        reload
      end

      ##
      # Remove all statements associated with this instance from the
      # repository. This will delete statements unassociated with the current
      # projection.
      #
      # @return [true, false] Whether or not the destroy was successful
      def destroy_resource!
        self.class.repository_or_fail.delete([@subject,nil,nil])
      end

      ##
      # Save changes in this instance to the repository.
      #
      # @return [true, false] Whether or not the save was successful
      def save!
        unless self.class.validators.empty?
          errors.clear
          self.class.validators.each do | validator | self.send(validator) end
          if errors.empty?
            _update!
          else
            raise(ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.each.join(';'))
          end
        else
          _update!
        end
      end

      ##
      # Save changes to the repository
      #
      # @private
      def _update!
        _destroy_attributes(@original_attributes)
        self.class.repository_or_fail.insert(*self)
        @original_attributes = @attributes.dup
      end
 
      ## 
      # The `RDF.type` associated with this class.
      #
      # @return [nil,RDF::URI] The RDF type associated with this instance's class.
      def type
        self.class.type
      end
 
      ##
      # `type` is a special property which is associated with the class and not
      # the instance.  Always raises a TypeError to try and assign it.  
      #
      # @raise [TypeError] always
      def type=(type)
        raise TypeError, "Cannot reassign RDF.type for #{self}; consider appending to a has_many :types"
      end

      ##
      # Returns the RDF representation of this resource.
      #
      # @return [RDF::Enumerable]
      def to_rdf
        self
      end
      
      ##
      # Returns the URI representation of this resource, if available.  If this
      # resource's subject is a BNode, raises a NoMethodError.
      #
      # @return [RDF::URI]
      # @raise [NoMethodError]
      def to_uri
        #uri || (raise NoMethodError
      end

      ##
      # A developer-friendly view of this projection
      #
      # @private
      def inspect
        "<#{self.class}:#{self.object_id} uri: #{@subject}>"
      end
 
      ##
      # Enumerate each RDF statement that makes up this projection.  This makes
      # each instance an `RDF::Enumerable`, with all of the nifty benefits
      # thereof.  See <http://rdf.rubyforge.org/RDF/Enumerable.html> for
      # information on arguments.
      #
      # @see http://rdf.rubyforge.org/RDF/Enumerable.html
      def each(*args, &block)
        return RDF::Enumerator.new(self, :each) unless block_given?
        repository = repository_for_attributes(@attributes)
        repository.insert(RDF::Statement.new(@subject, RDF.type, type)) unless type.nil?
        repository.each(*args, &block)
      end

      ##
      # Sets the given attribute to the given value.
      #
      # @private
      def attribute_set(name, value)
        @attributes[name] = value
      end

      ##
      # Get the current value for the given attribute
      #
      # @private
      def attribute_get(name)
        case self.class.is_list?(name)
          when true
            @attributes[name] ||= []
          when false   
            @attributes[name]
        end
      end

      ##
      # Create an RDF::Repository for the given attributes hash.  This could
      # just as well be a class method but is only used here in #save! and
      # #destroy!, so it is defined here for simplicity.  
      #
      # @param [Hash] attributes The attributes to create a repository for
      # @private
      def repository_for_attributes(attributes)
        repo = RDF::Repository.new
        attributes.each do | name, attribute |
          if self.class.is_list?(name)
            new = []
            attribute.each do |value|
              value = self.class.build_rdf_value(value, self.class.properties[name][:type])
              new << RDF::Statement.new(@subject, self.class.properties[name][:predicate], value)
            end
            repo.insert(*new)
          else
            value = self.class.build_rdf_value(attribute, self.class.properties[name][:type])
            repo.insert(RDF::Statement.new(@subject, self.class.properties[name][:predicate], value))
          end
        end
        repo
      end

      ##
      # Compare this instance with another instance.  The comparison is done on
      # an RDF level, and will work across subclasses as long as the attributes
      # are the same.
      # 
      # @see http://rdf.rubyforge.org/isomorphic/
      def ==(other)
        case other
          # TODO: define behavior for equality on subclasses.
          # TODO: should we compare attributes here?
          when self.class
            @subject == other.uri 
          when RDF::Enumerable
            self.isomorphic_with?(other)
          else
            false
        end
      end

      ##
      # Returns true for :to_uri if this instance's subject is a URI, and false if it is not.
      # Returns true for :to_node if this instance's subject is a Node, and false if it is not.
      # Calls super otherwise.
      #
      # @private
      def respond_to?(*args)
        case args[0]
          when :to_uri
            @subject.respond_to?(:to_uri)
          when :to_node
            @subject.node?
          else
            super(*args)
        end
      end

      ##
      # Returns the RDF::URI associated with this instance if this instance's
      # subject is an RDF::URI, and nil otherwise.
      #
      # @return [RDF::URI,nil]
      def uri
        @subject.respond_to?(:to_uri) ? @subject : nil
      end

      ##
      # The validation errors collection associated with this instance.
      #
      # @return [Spira::Errors]
      # @see Spira::Errors
      def errors
        @errors ||= Spira::Errors.new
      end

      ## We have defined #each and can do this fun RDF stuff by default
      include ::RDF::Enumerable, ::RDF::Queryable

      ## Include the base validation functions
      include Spira::Resource::Validations

    end  
  end
end
