require "set"
require "active_model"
require "rdf/isomorphic"
require "active_support/core_ext/hash/indifferent_access"

require "spira/resource"
require "spira/persistence"
require "spira/validations"
require "spira/reflections"
require "spira/serialization"

module Spira

  ##
  # Spira::Base aims to perform similar to ActiveRecord::Base
  # You should inherit your models from it.
  #
  class Base
    extend ActiveModel::Callbacks
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Dirty
    include ActiveModel::Serialization

    include ::RDF, ::RDF::Enumerable, ::RDF::Queryable, Utils

    define_model_callbacks :save, :destroy, :create, :update

    ##
    # This instance's URI.
    #
    # @return [RDF::URI]
    attr_reader :subject

    class << self
      attr_reader :reflections, :properties

      def types
        Set.new
      end

      ##
      # The base URI for this class.  Attempts to create instances for non-URI
      # objects will be appended to this base URI.
      #
      # @return [Void]
      def base_uri
        # should be redefined in children, if required
        # see also Spira::Resource.configure :base_uri option
        nil
      end

      ##
      # The default vocabulary for this class.  Setting a default vocabulary
      # will allow properties to be defined without a `:predicate` option.
      # Predicates will instead be created by appending the property name to
      # the given string.
      #
      # @return [Void]
      def default_vocabulary
        # should be redefined in children, if required
        # see also Spira::Resource.configure :default_vocabulary option
        nil
      end

      def serialize(node, options = {})
        if node.respond_to?(:subject)
          node.subject
        elsif node.respond_to?(:blank?) && node.blank?
          nil
        else
          raise TypeError, "cannot serialize #{node.inspect} as a Spira resource"
        end
      end

      def unserialize(value, options = {})
        if value.respond_to?(:blank?) && value.blank?
          nil
        else
          # Spira resources are instantiated as "promised"
          # to avoid instantiation loops in case of resource-to-resource relations.
          promise { instantiate_record(value) }
        end
      end


      private

      def inherited(child)
        child.instance_variable_set :@properties, @properties.dup
        child.instance_variable_set :@reflections, @reflections.dup
        super
      end

      def instantiate_record(subj)
        new(:_subject => id_for(subj))
      end

    end # class methods


    def id
      new_record? ? nil : subject.path.split(/\//).last
    end

    ##
    # Initialize a new Spira::Base instance of this resource class using
    # a new blank node subject.  Accepts a hash of arguments for initial
    # attributes.  To use a URI or existing blank node as a subject, use
    # {Spira.for} instead.
    #
    # @param [Hash{Symbol => Any}] props Default attributes for this instance
    # @yield [self] Executes a given block
    # @yieldparam [self] self The newly created instance
    # @see Spira.for
    # @see RDF::URI#as
    # @see RDF::Node#as
    def initialize(props = {}, options = {})
      @subject = props.delete(:_subject) || RDF::Node.new
      @attrs = {}

      reload props

      yield self if block_given?
    end

    # Returns the attributes
    def attributes
      @attrs
    end

    # Freeze the attributes hash such that associations are still accessible, even on destroyed records.
    def freeze
      @attrs.freeze; self
    end

    # Returns +true+ if the attributes hash has been frozen.
    def frozen?
      @attrs.frozen?
    end

    ##
    # The `RDF.type` associated with this class.
    #
    # This just takes a first type from "types" list,
    # so make sure you know what you're doing if you use it.
    #
    # @return [nil,RDF::URI] The RDF type associated with this instance's class.
    def type
      self.class.type
    end

    ##
    # All `RDF.type` nodes associated with this class.
    #
    # @return [nil,RDF::URI] The RDF type associated with this instance's class.
    def types
      self.class.types
    end

    ##
    # Assign all attributes from the given hash.
    #
    def reload(props = {})
      reset_changes
      super
      assign_attributes(props)
      self
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
    # Compare this instance with another instance.  The comparison is done on
    # an RDF level, and will work across subclasses as long as the attributes
    # are the same.
    #
    # @see http://rdf.rubyforge.org/isomorphic/
    def ==(other)
      # TODO: define behavior for equality on subclasses.
      # TODO: should we compare attributes here?
      if self.class == other.class
        subject == other.uri
      elsif other.is_a?(RDF::Enumerable)
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
        subject.respond_to?(:to_uri)
      when :to_node
        subject.node?
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
      subject.respond_to?(:to_uri) ? subject : nil
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
      subject.node?
    end

    ##
    # Returns the Node subject of this resource, if available.  If this
    # resource's subject is a URI, raises a NoMethodError.
    #
    # @return [RDF::Node]
    # @raise [NoMethodError]
    def to_node
      subject.node? ? subject : (raise NoMethodError, "No such method: :to_uri (this instance's subject is not a URI)")
    end

    ##
    # Returns a new instance of this class with the new subject instead of self.subject
    #
    # @param [RDF::Resource] new_subject
    # @return [Spira::Base] copy
    def copy(new_subject)
      self.class.new(@attrs.merge(:_subject => new_subject))
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
    # Assign attributes to the resource
    # without persisting it.
    def assign_attributes(attrs)
      attrs.each do |name, value|
        attribute_will_change!(name.to_s)
        send "#{name}=", value
      end
    end


    private

    def reset_changes
      clear_changes_information
    end

    def write_attribute(name, value)
      name = name.to_s
      if self.class.properties[name]
        if @attrs[name].is_a?(Promise)
          changed_attributes[name] = @attrs[name] unless changed_attributes.include?(name)
          @attrs[name] = value
        else
          if value != read_attribute(name)
            attribute_will_change!(name)
            @attrs[name] = value
          end
        end
      else
        raise Spira::PropertyMissingError, "attempt to assign a value to a non-existing property '#{name}'"
      end
    end

    ##
    # Get the current value for the given attribute
    #
    def read_attribute(name)
      value = @attrs[name.to_s]

      refl = self.class.reflections[name]
      if refl && !value
        # yield default values for empty reflections
        case refl.macro
        when :has_many
          # TODO: this should be actually handled by the reflection class
          []
        end
      else
        value
      end
    end

    ## Localized properties functions

    def merge_localized_property(name, arg)
      values = read_attribute("#{name}_native")
      values.delete_if { |s| s.language == I18n.locale }
      values << serialize_localized_property(arg, I18n.locale) if arg
      values
    end

    def serialize_localized_property(value, locale)
      RDF::Literal.new(value, :language => locale)
    end

    def unserialize_localized_properties(values, locale)
      v = values.detect { |s| s.language == locale || s.simple? }
      v && v.object
    end

    def hash_localized_properties(values)
      values.inject({}) do |out, v|
        out[v.language] = v.object
        out
      end
    end

    def serialize_hash_localized_properties(values)
      values.map { |lang, property| RDF::Literal.new(property, :language => lang) }
    end

    # Build a Ruby value from an RDF value.
    def build_value(node, type)
      klass = classize_resource(type)
      if klass.respond_to?(:unserialize)
        klass.unserialize(node)
      else
        raise TypeError, "Unable to unserialize #{node} as #{type}"
      end
    end

    # Build an RDF value from a Ruby value for a property
    def build_rdf_value(value, type)
      klass = classize_resource(type)
      if klass.respond_to?(:serialize)
        klass.serialize(value)
      else
        raise TypeError, "Unable to serialize #{value} as #{type}"
      end
    end

    def valid_object?(node)
      node && (!node.literal? || node.valid?)
    end

    extend Resource
    extend Reflections
    include Types
    include Persistence
    include Validations
    include Serialization

    @reflections = HashWithIndifferentAccess.new
    @properties = HashWithIndifferentAccess.new
  end
end
