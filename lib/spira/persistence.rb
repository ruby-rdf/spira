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
      # Create a new instance with the given subject without any modification to
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

    # A resource is considered to be new if the repository
    # does not have statements where subject == resource type
    def new_record?
      !self.class.repository.has_subject?(subject)
    end

    def destroyed?
      @destroyed
    end

    def persisted?
      # FIXME: an object should be considered persisted
      # when its attributes (and their exact values) are all available in the storage.
      # This should check for !(changed? || new_record? || destroyed?) actually.
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
        destroy_model_data(*args)
      end
    end

    def destroy!(*args)
      destroy(*args) || raise(RecordNotSaved)
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
    # @param  [Hash{Symbol => Any}] options
    # @return [self]
    def update_attributes(properties, options = {})
      assign_attributes properties
      save options
    end

    ##
    # Reload all attributes for this instance.
    # This resource will block if the underlying repository
    # blocks the next time it accesses attributes.
    #
    def reload(props = {})
      props = props.stringify_keys
      reset_changes
      self.class.properties.each_key do |name|
        name = name.to_s
        attributes[name] =
          if props[name]
            # mark overridden properties as changed
            attribute_will_change!(name)
            props[name]
          else
            promise { retrieve_attribute(name) }
          end
      end
      self
    end


    private

    def reset_changes
      @previously_changed = changes
      @changed_attributes.clear
    end

    def create_or_update
      run_callbacks :save do
        # "create" callback is triggered only when persisting a resource definition
        persistance_callback = new_record? && type ? :create : :update
        run_callbacks persistance_callback do
          materizalize
          persist!
          reset_changes
        end
      end
      self
    end

    ##
    # Save changes to the repository
    #
    def persist!
      repo = self.class.repository
      self.class.properties.each do |name, property|
        value = read_attribute name
        if self.class.reflect_on_association(name)
          # TODO: for now, always persist associations,
          #       as it's impossible to reliably determine
          #       whether the "association property" was changed
          #       (e.g. for "in-place" changes like "association << 1")
          #       This should be solved by splitting properties
          #       into "true attributes" and associations
          #       and not mixing the both in @properties.
          repo.delete [subject, property[:predicate], nil]
          value.each do |val|
            store_attribute(name, val, property[:predicate], repo)
          end
        else
          if attribute_changed?(name.to_s)
            repo.delete [subject, property[:predicate], nil]
            store_attribute(name, value, property[:predicate], repo)
          end
        end
      end
      types.each do |type|
        # NB: repository won't accept duplicates,
        #     but this should be avoided anyway, for performance
        repo.insert RDF::Statement.new(subject, RDF.type, type)
      end
    end

    # "Materialize" the resource:
    # assign a persistable subject to a non-persisted resource,
    # so that it can be properly stored.
    def materizalize
      if new_record? && subject.anonymous? && type
        # TODO: doesn't subject.anonymous? imply subject.id == nil ???
        @subject = self.class.id_for(subject.id)
      end
    end

    def store_attribute(property, value, predicate, repository)
      unless value.nil?
        val = build_rdf_value(value, self.class.properties[property][:type])
        repository.insert RDF::Statement.new(subject, predicate, val)
      end
    end

    # Directly retrieve an attribute value from the storage
    def retrieve_attribute(name)
      property = self.class.properties[name]
      sts = self.class.repository.query(:subject => subject, :predicate => property[:predicate])
      if self.class.reflections[name]
        # TODO: the default reflection value should be provided by the reflection class
        Set.new.tap do |value|
          sts.each do |st|
            value << build_value(st.object, property[:type])
          end
        end
      else
        build_value(sts.first.object, property[:type]) unless sts.empty?
      end
    end

    # Destroy all model data
    # AND non-model data, where this resource is referred to as object.
    def destroy_model_data(*args)
      if self.class.repository.delete(*statements) && self.class.repository.delete([nil, nil, subject])
        @destroyed = true
        freeze
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

  end
end
