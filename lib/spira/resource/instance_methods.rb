require 'rdf/isomorphic'
require 'set'

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

      # Marker for whether or not a field has been set or not; distinguishes
      # nil and unset.
      # @private
      NOT_SET = ::Object.new.freeze

      ##
      # This instance's URI.
      #
      # @return [RDF::URI]
      attr_reader :subject

      ## 
      # Initialize a new Spira::Resource instance of this resource class using
      # a new blank node subject.  Accepts a hash of arguments for initial
      # attributes.  To use a URI or existing blank node as a subject, use
      # {Spira::Resource::ClassMethods#for} instead.
      #
      # @param [Hash{Symbol => Any}] opts Default attributes for this instance
      # @yield [self] Executes a given block and calls `#save!`
      # @yieldparam [self] self The newly created instance
      # @see Spira::Resource::ClassMethods#for
      # @see RDF::URI#as
      # @see RDF::Node#as
      def initialize(opts = {})
        @subject = opts[:_subject] || RDF::Node.new
        reload(opts)
        if block_given?
          yield(self)
          save!
        end
        self
      end
  
      ##
      # Reload all attributes for this instance, overwriting or setting
      # defaults with the given opts.  This resource will block if the
      # underlying repository blocks the next time it accesses attributes.
      #
      # @param   [Hash{Symbol => Any}] opts
      # @option opts [Symbol] :any A property name.  Sets the given property to the given value.
      def reload(opts = {})
        @cache = opts[:_cache] || RDF::Util::Cache.new
        @cache[subject] = self
        @dirty = {}
        @attributes = {}
        @attributes[:current] = {}
        @attributes[:copied] = {}
        self.class.properties.each do |name, predicate|
          case opts[name].nil?
            when false
              attribute_set(name, opts[name])
            when true
              @attributes[:copied][name] = NOT_SET
          end
        end
        @attributes[:original] = promise { reload_attributes }
      end

      ##
      # Load this instance's attributes.  Overwrite loaded values with attributes in the given options.
      #
      # @return [Hash{Symbol => Any}] attributes
      # @private
      def reload_attributes()
        statements = self.class.repository_or_fail.query(:subject => @subject).to_a
        attributes = {}

        # Set attributes for each statement corresponding to a predicate
        self.class.properties.each do |name, property|
          if self.class.is_list?(name)
            values = Set.new
            collection = statements.select{|s| s.subject == @subject && s.predicate == property[:predicate]} unless statements.empty?
            unless collection.nil?
              collection.each do |statement|
                values << self.class.build_value(statement,property[:type], @cache)
              end
            end
            attributes[name] = values
          else
            statement = statements.select{|s| s.subject == @subject && s.predicate == property[:predicate]}.first unless statements.empty?
            attributes[name] = self.class.build_value(statement, property[:type], @cache)
          end
        end
        attributes
      end

      ##
      # Returns a hash of name => value for this instance's attributes
      #
      # @return [Hash{Symbol => Any}] attributes
      def attributes
        attributes = {}
        self.class.properties.keys.each do |property|
          attributes[property] = attribute_get(property)
        end
        attributes
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
      # Delete this instance from the repository.
      #
      # @param [Symbol] what
      # @example Delete all fields defined in the model
      #     @object.destroy!
      # @example Delete all instances of this object as the subject of a triple, including non-model data @object.destroy!
      #     @object.destroy!(:subject)
      # @example Delete all instances of this object as the object of a triple
      #     @object.destroy!(:object)
      # @example Delete all triples with this object as the subject or object
      #     @object.destroy!(:completely)
      # @return [true, false] Whether or not the destroy was successful
      def destroy!(what = nil)
        before_destroy if self.respond_to?(:before_destroy, true)
        result = case what
          when nil
            _destroy_attributes(attributes, :destroy_type => true) != nil
          when :subject
            self.class.repository_or_fail.delete([subject, nil, nil]) != nil
          when :object
            self.class.repository_or_fail.delete([nil, nil, subject]) != nil
          when :completely
            destroy!(:subject) && destroy!(:object)
        end
        after_destroy if self.respond_to?(:after_destroy, true) if result
        result
      end

      ##
      # Save changes in this instance to the repository.
      #
      # @return [self] self
      def save!
        existed = (self.respond_to?(:before_create, true) || self.respond_to?(:after_create, true)) && !self.type.nil? && exists?
        before_create if self.respond_to?(:before_create, true) && !self.type.nil? && !existed
        before_save if self.respond_to?(:before_save, true)
        # we use the non-raising validate and check it to make a slightly different error message.  worth it?...
        case validate
          when true
            _update!
          when false
            raise(ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.each.join(';'))
        end
        after_create if self.respond_to?(:after_create, true) && !self.type.nil? && !existed
        after_save if self.respond_to?(:after_save, true)
        self
      end

      ##
      # Update multiple attributes of this repository.
      #
      # @example Update multiple attributes
      #     person.update(:name => 'test', :age => 10)
      #     #=> person
      #     person.name
      #     #=> 'test'
      #     person.age
      #     #=> 10
      #     person.dirty?
      #     #=> true
      # @param  [Hash{Symbol => Any}] properties
      # @return [self]
      def update(properties)
        properties.each do |property, value|
          attribute_set(property, value)
        end
        after_update if self.respond_to?(:after_update, true)
        self
      end

      ##
      # Equivalent to #update followed by #save!
      #
      # @example Update multiple attributes and save the changes
      #     person.update!(:name => 'test', :age => 10)
      #     #=> person
      #     person.name
      #     #=> 'test'
      #     person.age
      #     #=> 10
      #     person.dirty?
      #     #=> false
      # @param  [Hash{Symbol => Any}] properties
      # @return [self]
      def update!(properties)
        update(properties)
        save!
      end

      ##
      # Save changes to the repository
      #
      # @private
      def _update!
        repo = self.class.repository_or_fail
        self.class.properties.each do |property, predicate|
          value = attribute_get(property)
          if dirty?(property)
            repo.delete([subject, predicate[:predicate], nil])
            if self.class.is_list?(property)
              value.each do |val|
                store_attribute(property, val, predicate[:predicate], repo)
              end
            else
              store_attribute(property, value, predicate[:predicate], repo)
            end
          end
          @attributes[:original][property] = value
          @dirty[property] = nil
          @attributes[:copied][property] = NOT_SET
        end
        repo.insert(RDF::Statement.new(@subject, RDF.type, type)) if type
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
      # A developer-friendly view of this projection
      #
      # @private
      def inspect
        "<#{self.class}:#{self.object_id} @subject: #{@subject}>"
      end
 
      ##
      # Enumerate each RDF statement that makes up this projection.  This makes
      # each instance an `RDF::Enumerable`, with all of the nifty benefits
      # thereof.  See <http://rdf.rubyforge.org/RDF/Enumerable.html> for
      # information on arguments.
      #
      # @see http://rdf.rubyforge.org/RDF/Enumerable.html
      def each(*args, &block)
        return enum_for(:each) unless block_given?
        repository = repository_for_attributes(attributes)
        repository.insert(RDF::Statement.new(@subject, RDF.type, type)) unless type.nil?
        repository.each(*args, &block)
      end

      ##
      # The number of RDF::Statements this projection has.
      #
      # @see http://rdf.rubyforge.org/RDF/Enumerable.html#count
      def count
        each.size
      end

      ##
      # Sets the given attribute to the given value.
      #
      # @private
      def attribute_set(name, value)
        @dirty[name] = true
        @attributes[:current][name] = value
      end

      ##
      # Returns true if the given attribute has been changed from the backing store
      #
      def dirty?(name = nil)
        case name
          when nil
            self.class.properties.keys.any? { |key| dirty?(key) }
          else
            case
              when @dirty[name] == true
                true
              else
                case @attributes[:copied][name]
                  when NOT_SET
                    false
                  else
                    @attributes[:copied][name] != @attributes[:original][name]
                end
            end
          end
      end

      ##
      # Get the current value for the given attribute
      #
      # @private
      def attribute_get(name)
        case @dirty[name]
          when true
            @attributes[:current][name]
          else
            case @attributes[:copied][name].equal?(NOT_SET)
              when true
                dup = if @attributes[:original][name].is_a?(Spira::Resource)
                  @attributes[:original][name]
                else
                  begin
                    @attributes[:original][name].dup
                  rescue TypeError
                    @attributes[:original][name]
                  end
                end
                @attributes[:copied][name] = dup
              when false
                @attributes[:copied][name]
            end
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
        RDF::Repository.new.tap do |repo|
          attributes.each do | name, attribute |
            predicate = self.class.properties[name][:predicate]
            if self.class.is_list?(name)
              attribute.each do |value|
                store_attribute(name, value, predicate, repo)
              end
            else
              store_attribute(name, attribute, predicate, repo)
            end
          end
        end
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
      # Returns the URI representation of this resource, if available.  If this
      # resource's subject is a BNode, raises a NoMethodError.
      #
      # @return [RDF::URI]
      # @raise [NoMethodError]
      def to_uri
        uri || (raise NoMethodError, "No such method: :to_uri (this instance's subject is not a URI)")
      end

      ##
      # Returns true if the subject associated with this instance is a blank node.
      #
      # @return [true, false]
      def node?
        @subject.node?
      end

      ##
      # Returns the Node subject of this resource, if available.  If this
      # resource's subject is a URI, raises a NoMethodError.
      #
      # @return [RDF::Node]
      # @raise [NoMethodError]
      def to_node
        @subject.node? ? @subject : (raise NoMethodError, "No such method: :to_uri (this instance's subject is not a URI)")
      end

      ##
      # The validation errors collection associated with this instance.
      #
      # @return [Spira::Errors]
      # @see Spira::Errors
      def errors
        @errors ||= Spira::Errors.new
      end

      ##
      # Run any model validations and populate the errors object accordingly.  
      # Returns true if the model is valid, false otherwise
      #
      # @return [True, False]
      def validate
        unless self.class.validators.empty?
          errors.clear
          self.class.validators.each do | validator | self.send(validator) end
        end
        errors.empty?
      end

      ## 
      # Run validations on this model and raise a Spira::ValidationError if the validations fail.
      #
      # @see #validate
      # @return true
      def validate!
        validate || raise(ValidationError, "Failed to validate #{self.inspect}: " + errors.each.join(';'))
      end

      ##
      # Returns true if any data exists for this subject in the backing RDF store
      #
      # @return [Boolean]
      def exists?
        !data.empty?
      end
      alias_method :exist?, :exists?
    
      ##
      # Returns an Enumerator of all RDF data for this subject, not just model data.
      #
      # @see #each
      # @see http://rdf.rubyforge.org/RDF/Enumerable.html
      # @return [Enumerator]
      def data
        self.class.repository.query(:subject => subject)
      end

      ##
      # Returns a new instance of this class with the new subject instead of self.subject
      #
      # @param [RDF::Resource] new_subject
      # @return [Spira::Resource] copy
      def copy(new_subject)
        copy = self.class.for(new_subject)
        self.class.properties.each_key { |property| copy.attribute_set(property, self.attribute_get(property)) }
        copy
      end

      ##
      # Returns a new instance of this class with the new subject instead of
      # self.subject after saving the new copy to the repository.
      #
      # @param [RDF::Resource] new_subject
      # @return [Spira::Resource, String] copy
      def copy!(new_subject)
        copy(new_subject).save!
      end

      ##
      # Copies all data, including non-model data, about this resource to
      # another URI.  The copy is immediately saved to the repository.
      #
      # @param [RDF::Resource] new_subject
      # @return [Spira::Resource, String] copy
      def copy_resource!(new_subject)
        new_subject = self.class.id_for(new_subject)
        update_repository = RDF::Repository.new
        data.each do |statement|
          update_repository << RDF::Statement.new(new_subject, statement.predicate, statement.object) 
        end
        self.class.repository.insert(update_repository)
        new_subject.as(self.class)
      end

      ## 
      # Rename this resource in the repository to the new given subject.
      # Changes are immediately saved to the repository.
      #
      # @param [RDF::Resource] new_subject
      # @return [Spira::Resource, String] new_resource
      def rename!(new_subject)
        new = copy_resource!(new_subject)
        object_statements = self.class.repository.query(:object => subject)
        update_repository = RDF::Repository.new
        object_statements.each do |statement|
          update_repository << RDF::Statement.new(statement.subject, statement.predicate, new.subject)
        end
        self.class.repository.insert(update_repository)
        destroy!(:completely)
        new
      end  

      ## We have defined #each and can do this fun RDF stuff by default
      include ::RDF::Enumerable, ::RDF::Queryable

      ## Include the base validation functions
      include Spira::Resource::Validations


      private

      def store_attribute(property, value, predicate, repository)
        if value
          val = self.class.build_rdf_value(value, self.class.properties[property][:type])
          repository.insert(RDF::Statement.new(subject, predicate, val))
        end
      end

    end  
  end
end
