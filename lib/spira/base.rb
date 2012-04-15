require "active_model"
require "active_support/hash_with_indifferent_access"
require "rdf/isomorphic"
require "set"

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
    include ::RDF, ::RDF::Enumerable, ::RDF::Queryable

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
      # The number of URIs projectable as a given class in the repository.
      # This method is only valid for classes which declare a `type` with the
      # `type` method in the Resource.
      #
      # @raise  [Spira::NoTypeError] if the resource class does not have an RDF type declared
      # @return [Integer] the count
      def count
        raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." if type.nil?
        repository.query(:predicate => RDF.type, :object => type).subjects.count
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
        raise Spira::NoTypeError, "Cannot count a #{self} without a reference type URI." if type.nil?

        if block_given?
          repository.query(:predicate => RDF.type, :object => type).each_subject do |subject|
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

      def serialize(node, options = {})
        node
      end

      def unserialize(value, options = {})
        if value.respond_to?(:blank?) && value.blank?
          nil
        else
          self.for value, options
        end
      end


      private

      def inherited(child)
        child.instance_variable_set :@properties, @properties.dup
        child.instance_variable_set :@reflections, @reflections.dup
        super
      end

      ##
      # A cache of iterated instances of this projection
      #
      # @return [RDF::Util::Cache]
      # @private
      def cache
        @cache ||= RDF::Util::Cache.new
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
      reload props
      yield self if block_given?
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

    extend Resource
    extend Reflections
    include Types
    include Persistence
    include Validations

    @reflections = HashWithIndifferentAccess.new
    @properties = HashWithIndifferentAccess.new
  end
end
