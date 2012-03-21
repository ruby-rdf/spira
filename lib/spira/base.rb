require "active_model"
require "active_support/hash_with_indifferent_access"
require "rdf/isomorphic"
require "set"

require "spira/dsl"
require "spira/validations"
require "spira/reflections"

module Spira

  ##
  # Spira::Base aims to perform similar to ActiveRecord::Base
  # You should inherit your models from it.
  #
  class Base
    extend ActiveModel::Callbacks
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    extend Spira::DSL
    extend Spira::Reflections
    include Spira::Types
    include Spira::Validations
    include ::RDF, ::RDF::Enumerable, ::RDF::Queryable

    define_model_callbacks :save, :destroy, :create, :update, :validation

    class_attribute :properties, :reflections, :instance_reader => false, :instance_writer => false
    self.reflections = HashWithIndifferentAccess.new

    ##
    # This instance's URI.
    #
    # @return [RDF::URI]
    attr_reader :subject

    ##
    # The validation errors collection associated with this instance.
    #
    # @return [Spira::Errors]
    # @see Spira::Errors
    attr_reader :errors

    # Marker for whether or not a field has been set or not;
    # distinguishes nil and unset.
    NOT_SET = ::Object.new.freeze

    class << self
      def find(scope, args = {})
        conditions = args[:conditions] || {}
        options = args.except(:conditions)

        limit = options[:limit] || -1

        case scope
        when :first
          find_all(conditions, :limit => 1).first
        when :all
          find_all(conditions, :limit => limit)
        else
          find_by_id scope
        end
      end

      def all(args = {})
        find(:all, args)
      end

      def first(args = {})
        find(:first, args)
      end

      ##
      # The current repository for this class
      #
      # @return [RDF::Repository, nil]
      def repository
	name = @repository_name || :default
	Spira.repository(name) || (raise Spira::NoRepositoryError, "#{self} is configured to use :#{name} as a repository, but it has not been set.")
      end

      ##
      # Create a new projection instance of this class for the given URI.  If a
      # class has a base_uri given, and the argument is not an `RDF::URI`, the
      # given identifier will be appended to the base URI.
      #
      # Spira does not have 'find' or 'create' functions.  As RDF identifiers
      # are globally unique, they all simply 'are'.
      #
      # On calling `for`, a new projection is created for the given URI.  The
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
      # @yield [self] Executes a given block and calls `#save!`
      # @yieldparam [self] self The newly created instance
      # @return  [Spira::Base] The newly created instance
      # @see http://rdf.rubyforge.org/RDF/URI.html
      def for(identifier, attributes = {}, &block)
	self.project(id_for(identifier), attributes, &block)
      end
      alias_method :[], :for

      ##
      # Create a new instance with the given subjet without any modification to
      # the given subject at all.  This method exists to provide an entry point
      # for implementing classes that want to create a more intelligent .for
      # and/or .id_for for their given use cases, such as simple string
      # appending to base URIs or calculated URIs from other representations.
      #
      # @example Using simple string concatentation with base_uri in .for instead of joining delimiters
      #     def for(identifier, attributes = {}, &block)
      #       self.project(RDF::URI(self.base_uri.to_s + identifier.to_s), attributes, &block)
      #     end
      # @param [RDF::URI, RDF::Node] subject
      # @param [Hash{Symbol => Any}] attributes Initial attributes
      # @return [Spira::Base] the newly created instance
      def project(subject, attributes = {}, &block)
	if !type.nil? && attributes[:type]
	  raise TypeError, "#{self} has an RDF type, #{self.type}, and cannot accept one as an argument."
	end
	new(attributes.merge(:_subject => subject), &block)
      end

      ##
      # Creates a URI or RDF::Node based on a potential base_uri and string,
      # URI, or Node, or Addressable::URI.  If not a URI or Node, the given
      # identifier should be a string representing an absolute URI, or
      # something responding to to_s which can be appended to a base URI, which
      # this class must have.
      #
      # @param  [Any] Identifier
      # @return [RDF::URI, RDF::Node]
      # @raise  [ArgumentError] If this class cannot create an identifier from the given argument
      # @see http://rdf.rubyforge.org/RDF/URI.html
      # @see Spira.base_uri
      # @see Spira.for
      def id_for(identifier)
	case
	  # Absolute URI's go through unchanged
	when identifier.is_a?(RDF::URI) && identifier.absolute?
	  identifier
	  # We don't have a base URI to join this fragment with, so go ahead and instantiate it as-is.
	when identifier.is_a?(RDF::URI) && self.base_uri.nil?
	  identifier
	  # Blank nodes go through unchanged
	when identifier.respond_to?(:node?) && identifier.node?
	  identifier
	  # Anything that can be an RDF::URI, we re-run this case statement
	  # on it for the fragment logic above.
	when identifier.respond_to?(:to_uri) && !identifier.is_a?(RDF::URI)
	  id_for(identifier.to_uri)
	  # see comment with #to_uri above, this might be a fragment
	when identifier.is_a?(Addressable::URI)
	  id_for(RDF::URI.intern(identifier))
	  # This is a #to_s or a URI fragment with a base uri.  We'll treat them the same.
	  # FIXME: when #/ makes it into RDF.rb proper, this can all be wrapped
	  # into the one case statement above.
	else
	  uri = identifier.is_a?(RDF::URI) ? identifier : RDF::URI.intern(identifier.to_s)
	  case
	  when uri.absolute?
	    uri
	  when self.base_uri.nil?
	    raise ArgumentError, "Cannot create identifier for #{self} by String without base_uri; an RDF::URI is required"
	  else
	    separator = self.base_uri.to_s[-1,1] =~ /(\/|#)/ ? '' : '/'
	    RDF::URI.intern(self.base_uri.to_s + separator + identifier.to_s)
	  end
	end
      end


      ##
      # The number of URIs projectable as a given class in the repository.
      # This method is only valid for classes which declare a `type` with the
      # `type` method in the DSL.
      #
      # @raise  [Spira::NoTypeError] if the resource class does not have an RDF type declared
      # @return [Integer] the count
      def count
	raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." if @type.nil?
	repository.query(:predicate => RDF.type, :object => @type).subjects.count
      end

      ##
      # Clear the iteration cache
      #
      # @return [void]
      def reload
	@cache = nil
      end

      ##
      # Enumerate over all resources projectable as this class.  This method is
      # only valid for classes which declare a `type` with the `type` method in
      # the DSL.
      #
      # @raise  [Spira::NoTypeError] if the resource class does not have an RDF type declared
      # @overload each
      #   @yield [instance] A block to perform for each available projection of this class
      #   @yieldparam [self] instance
      #   @yieldreturn [Void]
      #   @return [Void]
      #
      # @overload each
      #   @return [Enumerator]
      def each
	raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." if @type.nil?

	if block_given?
	  repository.query(:predicate => RDF.type, :object => @type).each_subject do |subject|
	    cache[subject] ||= self.for(subject)
	    yield cache[subject]
	  end
	else
	  enum_for(:each)
	end
      end

      def find_by_id id
        self.for id
      end


      private

      def inherited(child)
        child.properties ||= HashWithIndifferentAccess.new
        # TODO: get rid of this
        # (shouldn't use "type" both as a DSL setter and class getter)
        child.instance_variable_set(:@type, type) if type
      end

      ##
      # A cache of iterated instances of this projection
      #
      # @return [RDF::Util::Cache]
      # @private
      def cache
	@cache ||= RDF::Util::Cache.new
      end

      ##
      # The list of validation functions for this projection
      #
      # @return [Array<Symbol>]
      def validators
	@validators ||= []
      end

      # Build a Ruby value from an RDF value.
      #
      # @private
      def build_value(node, type, cache)
        if cache[node]
          cache[node]
        else
          if type.respond_to?(:unserialize)
            type.unserialize(node)
          elsif type.is_a?(Symbol) || type.is_a?(String)
            klass = classize_resource(type)
            cache[node] = promise { klass.for(node, :_cache => cache) }
            cache[node]
          else
            raise TypeError, "Unable to unserialize #{node} as #{type}"
          end
        end
      end

      # Build an RDF value from a Ruby value for a property
      # @private
      def build_rdf_value(value, type)
        if type.respond_to?(:serialize)
	  type.serialize(value)
	else
          # value is a Spira resource of "type"?
          if value.class.ancestors.include?(Spira::Base)
            klass = classize_resource(type)
            if klass.ancestors.include?(value.class)
              value.subject
            else
              raise TypeError, "#{value} is an instance of #{value.class}, expected #{klass}"
            end
          else
            raise TypeError, "Unable to serialize #{value} as #{type}"
          end
        end
      end

      # Return the appropriate class object for a string or symbol
      # representation.  Throws errors correctly if the given class cannot be
      # located, or if it is not a Spira::Base
      #
      def classize_resource(type)
	klass = nil
	begin
	  klass = qualified_const_get(type.to_s)
	rescue NameError
	  raise NameError, "Could not find relation class #{type} (referenced as #{type} by #{self})"
	end
	unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Base)
	  raise TypeError, "#{type} is not a Spira Resource (referenced as #{type} by #{self})"
	end
	klass
      end

      # Resolve a constant from a string, relative to this class' namespace, if
      # available, and from root, otherwise.
      #
      # FIXME: this is not really 'qualified', but it's one of those
      # impossible-to-name functions.  Open to suggestions.
      #
      # @author njh
      # @private
      def qualified_const_get(str)
	path = str.to_s.split('::')
	from_root = path[0].empty?
	if from_root
	  from_root = []
	  path = path[1..-1]
	else
	  start_ns = ((Class === self)||(Module === self)) ? self : self.class
	  from_root = start_ns.to_s.split('::')
	end
	until from_root.empty?
	  begin
	    return (from_root+path).inject(Object) { |ns,name| ns.const_get(name) }
	  rescue NameError
	    from_root.delete_at(-1)
	  end
	end
	path.inject(Object) { |ns,name| ns.const_get(name) }
      end

      ##
      # Determine the type for a property based on the given type option
      #
      # @param [nil, Spira::Type, Constant] type
      # @return Spira::Type
      # @private
      def type_for(type)
	case
	when type.nil?
	  Spira::Types::Any
	when type.is_a?(Symbol) || type.is_a?(String)
	  type
	when !(Spira.types[type].nil?)
	  Spira.types[type]
	else
	  raise TypeError, "Unrecognized type: #{type}"
	end
      end

      ##
      # Determine the predicate for a property based on the given predicate, name, and default vocabulary
      #
      # @param  [#to_s, #to_uri] predicate
      # @param  [Symbol] name
      # @return [RDF::URI]
      # @private
      def predicate_for(predicate, name)
	case
	when predicate.respond_to?(:to_uri) && predicate.to_uri.absolute?
	  predicate
	when @default_vocabulary.nil?
	  raise ResourceDeclarationError, "A :predicate option is required for types without a default vocabulary"
	else
	  # FIXME: use rdf.rb smart separator after 0.3.0 release
	  separator = @default_vocabulary.to_s[-1,1] =~ /(\/|#)/ ? '' : '/'
	  RDF::URI.intern(@default_vocabulary.to_s + separator + name.to_s)
	end
      end

      def find_all conditions, options = {}
        patterns = [[:subject, RDF.type, type]]
        conditions.each do |name, value|
          patterns << [:subject, properties[name][:predicate], value]
        end

        q = RDF::Query.new do
          patterns.each do |pat|
            pattern pat
          end
        end

        [].tap do |results|
          repository.query(q) do |solution|
            break if options[:limit].zero?
            results << self.for(solution[:subject])
            options[:limit] -= 1
          end
        end
      end

    end # class methods


    def id
      new_record? ? nil : subject.path.split(/\//).last
    end

    # A resource is considered to be new
    # when its definition ("resource - RDF.type - X") is not persisted,
    # although its properties may be in the storage.
    def new_record?
      !self.class.all.detect{|rs| rs.subject == subject }
    end

    def destroyed?
      @destroyed
    end

    def persisted?
      !(new_record? || destroyed?)
    end

    def save(*)
      if run_callbacks(:validation) { validate }
        run_callbacks :save do
          # "create" callback is triggered only when persisting a resource definition
          persistance_callback = new_record? && type ? :create : :update
          run_callbacks persistance_callback do
            if new_record? && subject.anonymous? && type
              # "materialize" the resource
              @subject = self.class.id_for(subject.id)
            end
            persist!
          end
        end
        self
      else
        # return nil if could not save the record
        # (i.e. there are validation errors)
        nil
      end
    end

    def save!
      save || raise(ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.each.join(';'))
    end

    def destroy(*args)
      run_callbacks :destroy do
        (@destroyed ||= destroy!(*args)) && !!freeze
      end
    end

    def update_attributes(attributes, options = {})
      update(attributes)
      save
    end

    ##
    # Initialize a new Spira::Base instance of this resource class using
    # a new blank node subject.  Accepts a hash of arguments for initial
    # attributes.  To use a URI or existing blank node as a subject, use
    # {Spira.for} instead.
    #
    # @param [Hash{Symbol => Any}] opts Default attributes for this instance
    # @yield [self] Executes a given block
    # @yieldparam [self] self The newly created instance
    # @see Spira.for
    # @see RDF::URI#as
    # @see RDF::Node#as
    def initialize(opts = {})
      @subject = opts.delete(:_subject) || RDF::Node.new
      reload opts
      yield self if block_given?
    end

    ##
    # Reload all attributes for this instance, overwriting or setting
    # defaults with the given opts.  This resource will block if the
    # underlying repository blocks the next time it accesses attributes.
    #
    # @param   [Hash{Symbol => Any}] opts
    # @option opts [Symbol] :any A property name.  Sets the given property to the given value.
    def reload(opts = {})
      @errors = Spira::Errors.new
      @cache = opts.delete(:_cache) || RDF::Util::Cache.new
      @cache[subject] = self
      @dirty = HashWithIndifferentAccess.new
      @attributes = {}
      @attributes[:current] = HashWithIndifferentAccess.new
      @attributes[:copied] = reset_properties
      @attributes[:original] = promise { reload_properties }
      update opts
    end

    ##
    # Returns a hash of name => value for this instance's attributes
    #
    # @return [Hash{Symbol => Any}] attributes
    def attributes
      HashWithIndifferentAccess.new.tap do |attrs|
        self.class.properties.each do |name, _|
          attrs[name] = read_attribute name
        end
      end
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
      case what
      when nil
        destroy_properties(attributes, :destroy_type => true) != nil
      when :subject
        self.class.repository.delete([subject, nil, nil]) != nil
      when :object
        self.class.repository.delete([nil, nil, subject]) != nil
      when :completely
        destroy!(:subject) && destroy!(:object)
      end
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
        write_attribute property, value
      end
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
    # Run any model validations and populate the errors object accordingly.
    # Returns true if the model is valid, false otherwise
    #
    # @return [True, False]
    def validate
      unless self.class.send(:validators).empty?
        errors.clear
        self.class.send(:validators).each do | validator | self.send(validator) end
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
    # TODO: This method *maybe* should be obsoleted by #persisted? from ActiveModel;
    #       the name is also misleading because "exists?" is not the same as "!new_record?",
    #       which, unlike "exists?" cares only for the resource definition.
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
    # @return [Spira::Base] copy
    def copy(new_subject)
      self.class.for(new_subject).tap do |res|
        self.class.properties.each_key do |property|
          res.send :write_attribute, property, read_attribute(property)
        end
      end
    end

    ##
    # Returns a new instance of this class with the new subject instead of
    # self.subject after saving the new copy to the repository.
    #
    # @param [RDF::Resource] new_subject
    # @return [Spira::Base, String] copy
    def copy!(new_subject)
      copy(new_subject).save!
    end

    ##
    # Copies all data, including non-model data, about this resource to
    # another URI.  The copy is immediately saved to the repository.
    #
    # @param [RDF::Resource] new_subject
    # @return [Spira::Base, String] copy
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
    # @return [Spira::Base, String] new_resource
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


    private

    def store_attribute(property, value, predicate, repository)
      if value
        val = self.class.send(:build_rdf_value, value, self.class.properties[property][:type])
        repository.insert(RDF::Statement.new(subject, predicate, val))
      end
    end

    def write_attribute(name, value)
      if self.class.properties[name]
        @dirty[name] = true
        @attributes[:current][name] = value
      else
        raise Spira::PropertyMissingError, "attempt to assign a value to a non-existing property '#{name}'"
      end
    end

    ##
    # Get the current value for the given attribute
    #
    def read_attribute(name)
      case @dirty[name]
      when true
        @attributes[:current][name]
      else
        if @attributes[:copied][name].equal?(NOT_SET)
          dup = if @attributes[:original][name].is_a?(Spira::Base)
                  @attributes[:original][name]
                else
                  begin
                    @attributes[:original][name].dup
                  rescue TypeError
                    @attributes[:original][name]
                  end
                end
          @attributes[:copied][name] = dup
        else
          @attributes[:copied][name]
        end
      end
    end

    ##
    # Save changes to the repository
    #
    def persist!
      repo = self.class.repository
      self.class.properties.each do |property, predicate|
        value = read_attribute property
        if dirty?(property)
          repo.delete([subject, predicate[:predicate], nil])
          if self.class.reflect_on_association(property)
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
      self
    end

    ##
    # Create an RDF::Repository for the given attributes hash.  This could
    # just as well be a class method but is only used here in #save! and
    # #destroy!, so it is defined here for simplicity.
    #
    # @param [Hash] attributes The attributes to create a repository for
    def repository_for_attributes(attrs)
      RDF::Repository.new.tap do |repo|
        attrs.each do |name, attribute|
          predicate = self.class.properties[name][:predicate]
          if self.class.reflect_on_association(name)
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
    # Reload this instance's attributes.
    #
    # @return [Hash{Symbol => Any}] attributes
    def reload_properties
      statements = data

      HashWithIndifferentAccess.new.tap do |attrs|
        self.class.properties.each do |name, property|
          if self.class.reflect_on_association(name)
            value = Set.new
            statements.each do |st|
              if st.predicate == property[:predicate]
                value << self.class.send(:build_value, st.object, property[:type], @cache)
              end
            end
          else
            statement = statements.detect {|st| st.predicate == property[:predicate] }
            if statement
              value = self.class.send(:build_value, statement.object, property[:type], @cache)
            end
          end
          attrs[name] = value
        end
      end
    end

    ##
    # Remove the given attributes from the repository
    #
    # @param [Hash] attributes The hash of attributes to delete
    # @param [Hash{Symbol => Any}] opts Options for deletion
    # @option opts [true] :destroy_type Destroys the `RDF.type` statement associated with this class as well
    def destroy_properties(attrs, opts = {})
      repository = repository_for_attributes(attrs)
      repository.insert([@subject, RDF.type, self.class.type]) if (self.class.type && opts[:destroy_type])
      self.class.repository.delete(*repository)
    end

    def reset_properties
      HashWithIndifferentAccess.new.tap do |attrs|
        self.class.properties.each do |name, _|
          attrs[name] = NOT_SET
        end
      end
    end

  end
end
