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
      # A symbol name for the repository this class is currently using.
      attr_reader :repository_name

      ##
      # Handling module inclusions
      #
      # @private
      def included(child)
	inherited(child)
      end

      ##
      # Handling inheritance
      #
      # @private
      def inherited(child)
	# FIXME: avoid inheriting if you can,
	# as the ActiveModel-ish approach is no longer happy
	# with defining a Spira resource by "include Spira::Resource"
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
      # The current repository for this class
      #
      # @return [RDF::Repository, nil]
      # @private
      def repository
	name = @repository_name || :default
	Spira.repository(name)
      end

      ##
      # Get the current repository for this class, and raise a
      # Spira::NoRepositoryError if it is nil.
      #
      # @raise  [Spira::NoRepositoryError]
      # @return [RDF::Repository]
      # @private
      def repository_or_fail
	repository || (raise Spira::NoRepositoryError, "#{self} is configured to use :#{@repository_name || 'default'} as a repository, but it has not been set.")
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
      # @return  [Spira::Resource] The newly created instance
      # @see http://rdf.rubyforge.org/RDF/URI.html
      def for(identifier, attributes = {}, &block)
	self.project(id_for(identifier), attributes, &block)
      end

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
      # @return [Spira::Resource] the newly created instance
      def project(subject, attributes = {}, &block)
	if !self.type.nil? && attributes[:type]
	  raise TypeError, "#{self} has an RDF type, #{self.type}, and cannot accept one as an argument."
	end
	self.new(attributes.merge(:_subject => subject), &block)
      end

      ##
      # Alias for #for
      #
      # @see #for
      def [](*args)
	self.for(*args)
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
      # @see Spira::Resource.base_uri
      # @see Spira::Resource.for
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
      # @see Spira::Resource::DSL
      def count
	raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." if @type.nil?
	repository.query(:predicate => RDF.type, :object => @type).subjects.count
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
      # @see Spira::Resource::DSL
      def each(&block)
	raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." if @type.nil?
	case block_given?
	when false
	  enum_for(:each)
	else
	  repository_or_fail.query(:predicate => RDF.type, :object => @type).each_subject do |subject|
	    self.cache[subject] ||= self.for(subject)
	    block.call(cache[subject])
	  end
	end
      end

      ##
      # Returns true if the given property is a has_many property, false otherwise
      #
      # @return [true, false]
      def is_list?(property)
	@lists.has_key?(property)
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
      def build_value(statement, type, cache)
	case
	when statement == nil
	  nil
	when !cache[statement.object].nil?
	  cache[statement.object]
	when type.respond_to?(:unserialize)
	  type.unserialize(statement.object)
	when type.is_a?(Symbol) || type.is_a?(String)
	  klass = classize_resource(type)
	  cache[statement.object] = promise { klass.for(statement.object, :_cache => cache) }
	  cache[statement.object]
	else
	  raise TypeError, "Unable to unserialize #{statement.object} as #{type}"
	end
      end

      # Build an RDF value from a Ruby value for a property
      # @private
      def build_rdf_value(value, type)
	case
	when type.respond_to?(:serialize)
	  type.serialize(value)
	when value && value.class.ancestors.include?(Spira::Resource)
	  klass = classize_resource(type)
	  unless klass.ancestors.include?(value.class)
	    raise TypeError, "#{value} is an instance of #{value.class}, expected #{klass}"
	  end
	  value.subject
	when type.is_a?(Symbol) || type.is_a?(String)
	  klass = classize_resource(type)
	else
	  raise TypeError, "Unable to serialize #{value} as #{type}"
	end
      end

      # Return the appropriate class object for a string or symbol
      # representation.  Throws errors correctly if the given class cannot be
      # located, or if it is not a Spira::Resource
      #
      def classize_resource(type)
	klass = nil
	begin
	  klass = qualified_const_get(type.to_s)
	rescue NameError
	  raise NameError, "Could not find relation class #{type} (referenced as #{type} by #{self})"
	  klass.is_a?(Class) && klass.ancestors.include?(Spira::Resource)
	end
	unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Resource)
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

      ##
      # Add getters and setters for a property or list.
      # @private
      def add_accessors(name, opts)
	name_equals = (name.to_s + "=").to_sym

	self.send(:define_method,name_equals) do |arg|
	  attribute_set(name, arg)
	end
	self.send(:define_method,name) do
	  attribute_get(name)
	end

      end
    end
  end
end
