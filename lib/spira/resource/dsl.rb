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
      # @param  [String, RDF::URI] uri
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
      # @param  [String, RDF::URI] uri
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
        predicate = predicate_for(opts[:predicate], name)
        type = type_for(opts[:type])
        @properties[name] = { :predicate => predicate, :type => type }
        add_accessors(name,opts)
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
      # @see Spira::Resource::DSL#property
      def has_many(name, opts = {})
        property(name, opts)
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

      private

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
