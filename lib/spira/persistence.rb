module Spira
  module Persistence
    extend ActiveSupport::Concern

    module ClassMethods
      # Creates an object (or multiple objects) and saves it to the database, if validations pass.
      # The resulting object is returned whether the object was saved successfully to the database or not.
      #
      # The +attributes+ parameter can be either be a Hash or an Array of Hashes. These Hashes describe the
      # attributes on the objects that are to be created.
      #
      # +create+ respects mass-assignment security and accepts either +:as+ or +:without_protection+ options
      # in the +options+ parameter.
      #
      # ==== Examples
      #   # Create a single new object
      #   User.create(:first_name => 'Jamie')
      #
      #   # Create a single new object using the :admin mass-assignment security role
      #   User.create({ :first_name => 'Jamie', :is_admin => true }, :as => :admin)
      #
      #   # Create a single new object bypassing mass-assignment security
      #   User.create({ :first_name => 'Jamie', :is_admin => true }, :without_protection => true)
      #
      #   # Create an Array of new objects
      #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }])
      #
      #   # Create a single object and pass it into a block to set other attributes.
      #   User.create(:first_name => 'Jamie') do |u|
      #     u.is_admin = false
      #   end
      #
      #   # Creating an Array of new objects using a block, where the block is executed for each object:
      #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }]) do |u|
      #     u.is_admin = false
      #   end
      def create(attributes = nil, options = {}, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr, options, &block) }
        else
          object = new(attributes, options, &block)
          object.save
          object
        end
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
    end

    # A resource is considered to be new
    # when its definition ("resource - RDF.type - X") is not persisted,
    # although its other properties may already be in the storage.
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
      create_or_update
    end

    def save!(*)
      create_or_update || raise(RecordNotSaved)
    end

    def destroy(*args)
      run_callbacks :destroy do
        (@destroyed ||= destroy!(*args)) && !!freeze
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
    #     person.update_attributes(:name => 'test', :age => 10)
    #     #=> person
    #     person.name
    #     #=> 'test'
    #     person.age
    #     #=> 10
    #     person.dirty?
    #     #=> true
    # @param  [Hash{Symbol => Any}] properties
    # @return [self]
    def update_attributes(properties, options = {})
      update properties
      save
    end

    ##
    # Reload all attributes for this instance, overwriting or setting
    # defaults with the given opts.  This resource will block if the
    # underlying repository blocks the next time it accesses attributes.
    #
    # @param   [Hash{Symbol => Any}] props
    # @option opts [Symbol] :any A property name.  Sets the given property to the given value.
    def reload(props = {})
      @cache = props.delete(:_cache) || RDF::Util::Cache.new
      @cache[subject] = self
      @dirty = HashWithIndifferentAccess.new
      @attributes = {}
      @attributes[:current] = HashWithIndifferentAccess.new
      @attributes[:copied] = reset_properties
      @attributes[:original] = promise { reload_properties }
      update props
    end


    private

    def create_or_update
      run_callbacks :save do
        # "create" callback is triggered only when persisting a resource definition
        persistance_callback = new_record? && type ? :create : :update
        run_callbacks persistance_callback do
          materizalize
          persist!
        end
      end
    end

    def update(properties)
      properties.each do |property, value|
        # using a setter instead of write_attribute
        # to account for user-defined setter methods
        # (usually overriding standard ones)
        send "#{property}=", value
      end
    end

    ##
    # Save changes to the repository
    #
    def persist!
      repo = self.class.repository
      self.class.properties.each do |name, property|
        value = read_attribute name
        if dirty?(name)
          repo.delete([subject, property[:predicate], nil])
          if self.class.reflect_on_association(name)
            value.each do |val|
              store_attribute(name, val, property[:predicate], repo)
            end
          else
            store_attribute(name, value, property[:predicate], repo)
          end
        end
        @attributes[:original][name] = value
        @dirty[name] = nil
        @attributes[:copied][name] = NOT_SET
      end
      types.each do |type|
        repo.insert(RDF::Statement.new(subject, RDF.type, type))
      end
      self
    end

    # "Materialize" the resource:
    # assign a persistable subject to a non-persisted resource,
    # so that it can be properly stored.
    def materizalize
      if new_record? && subject.anonymous? && type
        @subject = self.class.id_for(subject.id)
      end
    end

    def store_attribute(property, value, predicate, repository)
      unless value.nil?
        val = build_rdf_value(value, self.class.properties[property][:type])
        repository.insert(RDF::Statement.new(subject, predicate, val))
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
                value << build_value(st.object, property[:type], @cache)
              end
            end
          else
            statement = statements.detect {|st| st.predicate == property[:predicate] }
            if statement
              value = build_value(statement.object, property[:type], @cache)
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
      repository.insert([subject, RDF.type, self.class.type]) if (self.class.type && opts[:destroy_type])
      self.class.repository.delete(*repository)
    end

    # Build a Ruby value from an RDF value.
    #
    # @private
    def build_value(node, type, cache)
      if cache[node]
        cache[node]
      else
        klass = classize_resource(type)
        if klass.respond_to?(:unserialize)
          if klass.ancestors.include?(Spira::Base)
            cache[node] = promise { klass.unserialize(node, :_cache => cache) }
          else
            klass.unserialize(node)
          end
        else
          raise TypeError, "Unable to unserialize #{node} as #{type}"
        end
      end
    end

    # Build an RDF value from a Ruby value for a property
    # @private
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

    # Return the appropriate class object for a string or symbol
    # representation.  Throws errors correctly if the given class cannot be
    # located, or if it is not a Spira::Base
    #
    def classize_resource(type)
      return type unless type.is_a?(Symbol) || type.is_a?(String)

      klass = nil
      begin
        klass = qualified_const_get(type.to_s)
      rescue NameError
        raise NameError, "Could not find relation class #{type} (referenced as #{type} by #{self})"
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

    def reset_properties
      HashWithIndifferentAccess.new.tap do |attrs|
        self.class.properties.each_key do |name|
          attrs[name] = NOT_SET
        end
      end
    end

  end
end
