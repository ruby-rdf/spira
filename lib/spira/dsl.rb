module Spira
  ##
  # This module consists of Spira::Base class methods which correspond to
  # the Spira resource class declaration DSL.  See {Spira::Base} for more
  # information.
  module DSL

    ##
    # A symbol name for the repository this class is currently using.
    attr_reader :repository_name

    ##
    # The name of the default repository to use for this class.  This
    # repository will be queried and written to instead of the :default
    # repository.
    #
    # @param  [Symbol] name
    # @return [Void]
    def default_source(name)
      @repository_name = name
      @repository = Spira.repository(name)
    end

    ##
    # The base URI for this class.  Attempts to create instances for non-URI
    # objects will be appended to this base URI.
    #
    # @param  [String, RDF::URI] base uri
    # @return [Void]
    def base_uri(uri = nil)
      @base_uri = uri unless uri.nil?
      @base_uri
    end

    ##
    # The default vocabulary for this class.  Setting a default vocabulary
    # will allow properties to be defined without a `:predicate` option.
    # Predicates will instead be created by appending the property name to
    # the given string.
    #
    # @param  [String, RDF::URI] base uri
    # @return [Void]
    def default_vocabulary(uri)
      @default_vocabulary = uri
    end


    ##
    # Add a property to this class.  A property is an accessor field that
    # represents an RDF predicate.
    #
    # @example A simple string property
    #     property :name, :predicate => FOAF.name, :type => String
    # @example A property which defaults to {Spira::Types::Any}
    #     property :name, :predicate => FOAF.name
    # @example An integer property
    #     property :age,  :predicate => FOAF.age, :type => Integer
    # @param  [Symbol] name The name of this property
    # @param  [Hash{Symbol => Any}] opts property options
    # @option opts [RDF::URI]            :predicate The RDF predicate which will refer to this property
    # @option opts [Spira::Type, String] :type      (Spira::Types::Any) The
    # type for this property.  If a Spira::Type is given, that class will be
    # used to serialize and unserialize values.  If a String is given, it
    # should be the String form of a Spira::Base class name (Strings are
    # used to prevent issues with load order).
    # @see Spira::Types
    # @see Spira::Type
    # @return [Void]
    def property(name, opts = {})
      predicate = predicate_for(opts[:predicate], name)
      type = type_for(opts[:type])
      properties[name] = HashWithIndifferentAccess.new(:predicate => predicate, :type => type)
      lists.delete(name)
      add_accessors(name, opts)
    end

    ##
    # The plural form of `property`.  `Has_many` has the same options as
    # `property`, but instead of a single value, a Ruby Array of objects will
    # be created instead.
    #
    # has_many corresponds to an RDF subject with several triples of the same
    # predicate.  This corresponds to a Ruby Set, which will be returned when
    # the property is accessed.  Arrays will be accepted for new values, but
    # ordering and duplicate values will be lost on save.
    #
    # @see Spira::Base::DSL#property
    def has_many(name, opts = {})
      property(name, opts)
      lists[name] = true
    end

    ##
    # Validate this model with the given validator function name.
    #
    # @example
    #     class Person < Spira::Base
    #       property :name, :predicate => FOAF.name
    #       validate :is_awesome
    #       def is_awesome
    #         assert(name =~ /Thor/, :name, "not awesome")
    #       end
    #     end
    # @param  [Symbol] validator
    # @return [Void]
    def validate(validator)
      validators << validator unless validators.include?(validator)
    end


    ##
    # Associate an RDF type with this class.  RDF resources can be multiple
    # types at once, but if they have an `RDF.type` statement for the given
    # URI, this class can #count them.
    #
    # @param  [RDF::URI] uri The URI object of the `RDF.type` triple
    # @return [Void]
    # @see http://rdf.rubyforge.net/RDF/URI.html
    # @see http://rdf.rubyforge.org/RDF.html#type-class_method
    # @see Spira::Base.count
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

  end
end
