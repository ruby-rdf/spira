require 'promise'

module Spira
  module Resource

    ##
    # This module consists of Spira::Resource class methods which correspond to
    # the Spira resource class declaration DSL.  See {Spira::Resource} for more
    # information.
    #
    # @see Spira::Resource
    # @see Spira::Resource::ClassMethods
    # @see Spira::Resource::InstanceMethods
    # @see Spira::Resource::Validations
    module DSL  

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
      # should be the String form of a Spira::Resource class name (Strings are
      # used to prevent issues with load order).  
      # @see Spira::Types
      # @see Spira::Type
      # @return [Void]
      def property(name, opts = {} )
        add_accessors(name,opts,:hash_accessors)
      end

      ##
      # The plural form of `property`.  `Has_many` has the same options as
      # `property`, but instead of a single value, a Ruby Array of objects will
      # be created instead.  Be warned that this should be a Set to match RDF
      # semantics, but this is not currently implemented.  Duplicate values of
      # an array will be lost on save.  
      #
      # @see Spira::Resource::DSL#property
      def has_many(name, opts = {})
        add_accessors(name,opts,:hash_accessors)
        @lists[name] = true
      end

      ##
      # Validate this model with the given validator function name.
      #
      # @example
      #     class Person
      #       include Spira::Resource
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
      # @see Spira::Resource::ClassMethods#count 
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

      # Build a Ruby value from an RDF value.
      #
      # @private
      def build_value(statement, type)
        case
          when statement == nil
            nil
          when type.is_a?(Class) && type.ancestors.include?(Spira::Type)
            type.unserialize(statement.object)
          when type.is_a?(Symbol) || type.is_a?(String)
            klass = begin 
              Kernel.const_get(type.to_s)
            rescue NameError
              unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Resource)
                raise TypeError, "#{type} is not a Spira Resource (referenced as #{type} by #{self}"
              end
            end
            promise { klass.for(statement.object) }
          else
            raise TypeError, "Unable to unserialize #{statement.object} as #{type}"
        end
      end

      # Build an RDF value from a Ruby value for a property
      # @private
      def build_rdf_value(value, type)
        case
          when type.is_a?(Class) && type.ancestors.include?(Spira::Type)
            type.serialize(value)
          when value && value.class.ancestors.include?(Spira::Resource)
            value.subject
          else
            raise TypeError, "Unable to serialize #{value} as #{type}"
        end
      end

      private

      ##
      # Add getters and setters for a property or list.
      # @private
      def add_accessors(name, opts, accessors_method)
        predicate = case
          when opts[:predicate]
            opts[:predicate]
          when @default_vocabulary.nil?
            raise TypeError, "A :predicate option is required for types without a default vocabulary"
          else @default_vocabulary
            separator = @default_vocabulary.to_s[-1,1] =~ /(\/|#)/ ? '' : '/'
            RDF::URI.new(@default_vocabulary.to_s + separator + name.to_s)
        end
        type = case
            when opts[:type].nil?
              Spira::Types::Any
            when opts[:type].is_a?(Symbol) || opts[:type].is_a?(String)
              opts[:type]
            when !(Spira.types[opts[:type]].nil?)
              Spira.types[opts[:type]]
            else
              raise TypeError, "Unrecognized type: #{opts[:type]}"
          end
        @properties[name] = {}
        @properties[name][:predicate] = predicate
        @properties[name][:type] = type
        name_equals = (name.to_s + "=").to_sym

        (getter,setter) = self.send(accessors_method, name, predicate, type)
        self.send(:define_method,name_equals, &setter) 
        self.send(:define_method,name, &getter) 

      end

      ##
      # Getter and Setter methods for predicates.
      # FIXME: this and add_accessors are from an older version in which
      # multiple versions of accessors existed, and can be refactored.
      # @private
      def hash_accessors(name, predicate, type)
        setter = lambda do |arg|
          attribute_set(name,arg)
        end

        getter = lambda do
          attribute_get(name)
        end

        [getter, setter]
      end

    end
  end
end
