require "active_support/core_ext/class"
require "spira/association_reflection"

module Spira
  module Resource
    ##
    # Configuration options for the Spira::Resource:
    #
    # @params[Hash] options
    #   :base_uri           :: base URI to be used for the resource
    #   :default_vocabulary :: default vocabulary to use for the properties
    #                          defined for this resource
    # All these configuration options are readable via
    # their respectively named Spira resource methods.
    #
    def configure(options = {})
      singleton_class.class_eval do
        { :base_uri => options[:base_uri],
          :default_vocabulary => options[:default_vocabulary]
        }.each do |name, value|
          # redefine reader methods only when required,
          # otherwise, use the ancestor methods
          if value
            define_method name do
              value
            end
          end
        end
      end
    end

    ##
    # Declare a type for the Spira::Resource.
    # You can declare multiple types for a resource
    # with multiple "type" assignments.
    # If no types are declared for a resource,
    # they are inherited from the parent resource.
    #
    # @params[RDF::URI] uri
    #
    def type(uri = nil)
      if uri
        if uri.is_a?(RDF::URI)
          ts = @types ? types : Set.new
          singleton_class.class_eval do
            define_method :types do
              ts
            end
          end
          @types = ts << uri
        else
          raise TypeError, "Type must be a RDF::URI"
        end
      else
        types.first
      end
    end

    ##
    # Add a property to this class.  A property is an accessor field that
    # represents an RDF predicate.
    #
    # @example A simple string property
    #     property :name, :predicate => RDF::Vocab::FOAF.name, :type => String
    # @example A property which defaults to {Spira::Types::Any}
    #     property :name, :predicate => RDF::Vocab::FOAF.name
    # @example An integer property
    #     property :age,  :predicate => RDF::Vocab::FOAF.age, :type => Integer
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
      if opts.delete(:localized)
        raise 'Only Spira::Types::Any properties can accept the :localized option' unless type_for(opts[:type]) == Spira::Types::Any
        define_localized_property_methods(name, opts)
        has_many "#{name}_native", opts.merge(:type => Spira::Types::Native)
      else
        unset_has_many(name)
        predicate = predicate_for(opts[:predicate], name)
        type = type_for(opts[:type])
        properties[name] = HashWithIndifferentAccess.new(:predicate => predicate, :type => type)

        define_attribute_method name
        define_method "#{name}=" do |arg|
          write_attribute name, arg
        end
        define_method name do
          read_attribute name
        end
      end
    end

    ##
    # The plural form of `property`. `Has_many` has the same options as
    # `property`, but instead of a single value, a Ruby Array of objects will
    # be created instead.
    #
    # has_many corresponds to an RDF subject with several triples of the same
    # predicate. This corresponds to a Ruby Array, which will be returned when
    # the property is accessed. Arrays will be accepted for new values, but
    # ordering and duplicate values will be lost on save.
    #
    # @see Spira::Base::DSL#property
    def has_many(name, opts = {})
      property(name, opts)

      reflections[name] = AssociationReflection.new(:has_many, name, opts)

      define_method "#{name.to_s.singularize}_ids" do
        records = send(name) || []
        records.map(&:id).compact
      end
      define_method "#{name.to_s.singularize}_ids=" do |ids|
        records = ids.map {|id| self.class.reflect_on_association(name).klass.unserialize(id) }.compact
        send "#{name}=", records
      end
    end

    private

    # Unset a has_many relation if it exists. Allow to redefine the cardinality of a relation in a subClass
    #
    # @private
    def unset_has_many(name)
      if reflections[name]
        reflections.delete(name)
        undef_method "#{name.to_s.singularize}_ids"
        undef_method "#{name.to_s.singularize}_ids="
      end
    end

    ##
    # Create the localized specific getter/setter for a given property
    #
    # @private
    def define_localized_property_methods(name, opts)
      define_method "#{name}=" do |arg|
        new_value = merge_localized_property(name, arg)
        write_attribute "#{name}_native", new_value
      end

      define_method name do
        value = read_attribute("#{name}_native")
        unserialize_localized_properties(value, I18n.locale)
      end

      define_method "#{name}_with_locales" do
        value = read_attribute("#{name}_native")
        hash_localized_properties(value)
      end

      define_method "#{name}_with_locales=" do |arg|
        value = serialize_hash_localized_properties(arg)
        write_attribute "#{name}_native", value
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
      when default_vocabulary.nil?
        raise ResourceDeclarationError, "A :predicate option is required for types without a default vocabulary"
      else
        # FIXME: use rdf.rb smart separator after 0.3.0 release
        separator = default_vocabulary.to_s[-1,1] =~ /(\/|#)/ ? '' : '/'
        RDF::URI.intern(default_vocabulary.to_s + separator + name.to_s)
      end
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
      when Spira.types[type]
        Spira.types[type]
      else
        raise TypeError, "Unrecognized type: #{type}"
      end
    end

  end
end
