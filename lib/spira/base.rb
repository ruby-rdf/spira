require "active_model"
require "rdf/isomorphic"
require "set"
require "active_support/core_ext/hash/indifferent_access"

require "spira/resource"
require "spira/persistence"
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
    include ActiveModel::Dirty

    # TODO: I don't think RDF::Enumerable should be included here
    include ::RDF, ::RDF::Enumerable, ::RDF::Queryable

    define_model_callbacks :save, :destroy, :create, :update

    ##
    # This instance's URI.
    #
    # @return [RDF::URI]
    attr_reader :subject

    attr_accessor :attributes

    class << self
      attr_reader :reflections, :properties

      def types
        Set.new
      end

      ##
      # Repository name for this class
      #
      # @return [Symbol]
      def repository_name
        # should be redefined in children, if required
        # see also Spira::Resource.configure :repository option
        :default
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


      ##
      # The current repository for this class
      #
      # @return [RDF::Repository, nil]
      def repository
        Spira.repository(repository_name)
      end

      ##
      # Simple finder method.
      #
      # @param [Symbol, ID] scope
      #   scope can be :all, :first or an ID
      # @param [Hash] args
      #   args can contain:
      #     :conditions - Hash of properties and values
      #     :limit      - Fixnum, limiting the amount of returned records
      # @return [Spira::Base, Set]
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
          instantiate_record(scope)
        end
      end

      def all(args = {})
        find(:all, args)
      end

      def first(args = {})
        find(:first, args)
      end

      ##
      # The number of URIs projectable as a given class in the repository.
      # This method is only valid for classes which declare a `type` with the
      # `type` method in the Resource.
      #
      # @raise  [Spira::NoTypeError] if the resource class does not have an RDF type declared
      # @return [Integer] the count
      def count
        raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." unless type
        repository.query(:predicate => RDF.type, :object => type).subjects.count
      end

      ##
      # Enumerate over all resources projectable as this class.  This method is
      # only valid for classes which declare a `type` with the `type` method in
      # the Resource.
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
        raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." unless type

        if block_given?
          repository.query(:predicate => RDF.type, :object => type).each_subject do |subject|
            yield instantiate_record(subject)
          end
        else
          enum_for(:each)
        end
      end

      def serialize(node, options = {})
        node
      end

      def unserialize(value, options = {})
        if value.respond_to?(:blank?) && value.blank?
          nil
        else
          instantiate_record(value)
        end
      end


      private

      def inherited(child)
        child.instance_variable_set :@properties, @properties.dup
        child.instance_variable_set :@reflections, @reflections.dup
        super
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
            results << instantiate_record(solution[:subject])
            options[:limit] -= 1
          end
        end
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

      @attributes = {}
      reload props

      yield self if block_given?
    end

    ##
    # The `RDF.type` associated with this class.
    #
    # @return [nil,RDF::URI] The RDF type associated with this instance's class.
    def type
      self.class.type
    end

    def types
      self.class.types
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
      if block_given?
        self.class.properties.each do |name, property|
          if value = read_attribute(name)
            if self.class.reflect_on_association(name)
              value.each do |val|
                node = build_rdf_value(val, property[:type])
                yield RDF::Statement.new(subject, property[:predicate], node) if can_store_node?(node)
              end
            else
              node = build_rdf_value(value, property[:type])
              yield RDF::Statement.new(subject, property[:predicate], node) if can_store_node?(node)
            end
          end
        end
        self.class.types.each do |t|
          yield RDF::Statement.new(subject, RDF.type, t)
        end
      else
        enum_for(:each)
      end
    end

    ##
    # The number of RDF::Statements this projection has.
    #
    # @see http://rdf.rubyforge.org/RDF/Enumerable.html#count
    def count
      each.size
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
        subject == other.uri
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
      self.class.new(attributes.merge(:_subject => new_subject))
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
        send "#{name}=", value
      end
    end


    private

    def write_attribute(name, value)
      name = name.to_s
      if self.class.properties[name]
        if attributes[name].is_a?(Promise)
          changed_attributes[name] = attributes[name] unless changed_attributes.include?(name)
          attributes[name] = value
        else
          if value != read_attribute(name)
            attribute_will_change!(name)
            attributes[name] = value
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
      value = attributes[name.to_s]
      # NB: RDF.rb (and probably others) does not work well with "promises",
      #     have to output a real value
      value = value.is_a?(Promise) ? value.force : value

      refl = self.class.reflections[name]
      if refl && !value
        # yield default values for empty reflections
        case refl.macro
        when :has_many
          # TODO: this should be actually handled by the reflection class
          Set.new
        end
      else
        value
      end
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
        # value is a Spira resource of "type"?
        if value.class.ancestors.include?(Spira::Base)
          if klass.ancestors.include?(value.class)
            value.subject
          else
            raise TypeError, "#{value} is an instance of #{value.class}, expected #{klass}"
          end
        else
          klass.serialize(value)
        end
      else
        raise TypeError, "Unable to serialize #{value} as #{type}"
      end
    end

    def can_store_node?(node)
      !node.literal? || node.valid?
    end

    extend Resource
    extend Reflections
    include Types
    include Persistence
    include Validations

    @reflections = HashWithIndifferentAccess.new
    @properties = HashWithIndifferentAccess.new
  end
end
