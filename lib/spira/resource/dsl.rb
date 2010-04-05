require 'promise'

module Spira
 module Resource

   # This module contains all user-exposed methods for use in building a model class.
   # It is used to extend classes that include Spira::Resource.
   # @see a little bit of magic in Spira::Resource#included as well--some
   # tricks need class_eval before this module is included.
   # @see Spira::Resource::ClassMethods for class methods available after class
   # definition 
   # @see Spira::Resource::InstanceMethods for instance methods available after
   # class definition
    module DSL  

      def default_source(name)
        @repository_name = name
        @repository = Spira.repository(name)
      end
  
      def base_uri(uri = nil)
        @base_uri = uri unless uri.nil?
        @base_uri
      end
      
      def default_vocabulary(uri)
        @default_vocabulary = uri
      end

      def property(name, opts = {} )
        add_accessors(name,opts,:hash_accessors)
      end

      def has_many(name, opts = {})
        add_accessors(name,opts,:hash_accessors)
        @lists[name] = true
      end

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

      #
      # @nodoc
      def build_value(statement, type)
        case
          when statement == nil
            nil
          when type == String
            statement.object.object.to_s
          when type == Integer
            statement.object.object
          when type.is_a?(Symbol)
            klass = Kernel.const_get(type.to_s.capitalize)
            raise TypeError, "#{klass} is not a Spira Resource (referenced as #{type} by #{self}" unless klass.ancestors.include? Spira::Resource
            promise { klass.find(statement.object) || klass.create(statement.object) }
        end
      end

      def build_rdf_value(value, type)
        case
          when value.class.ancestors.include?(Spira::Resource)
            value.uri
          when type == nil
            value
          when type == RDF::URI && value.is_a?(RDF::URI)
            value
          when type.is_a?(RDF::URI)
            RDF::Literal.new(value, :datatype => type)
          else
            RDF::Literal.new(value)
        end
      end

      private

      def add_accessors(name, opts, accessors_method)
        predicate = case
          when opts[:predicate]
            opts[:predicate]
          when @default_vocabulary.nil?
            raise TypeError, "A :predicate option is required for types without a default vocabulary"
          else @default_vocabulary
            separator = @default_vocabulary.to_s[-1,1] == "/" ? '' : '/'
            RDF::URI.new(@default_vocabulary.to_s + separator + name.to_s)
        end

        type = opts[:type] || String
        @properties[name] = {}
        @properties[name][:predicate] = predicate
        @properties[name][:type] = type
        name_equals = (name.to_s + "=").to_sym

        (getter,setter) = self.send(accessors_method, name, predicate, type)
        self.send(:define_method,name_equals, &setter) 
        self.send(:define_method,name, &getter) 

      end

      def hash_accessors(name, predicate, type)
        setter = lambda do |arg|
          attribute_set(name,arg)
        end

        getter = lambda do
          attribute_get(name)
        end

        [getter, setter]
      end

      def list_accessors(name, predicate, type)

        setter = lambda do |arg|
          old = @repo.query(:subject => @uri, :predicate => predicate)
          @repo.delete(*old.to_a) unless old.empty?
          new = []
          arg.each do |value|
            value = self.class.build_rdf_value(value, type)
            new << RDF::Statement.new(@uri, predicate, value)
          end
          @repo.insert(*new)
        end

        getter = lambda do
          values = []
          statements = @repo.query(:subject => @uri, :predicate => predicate)
          statements.each do |statement|
            values << self.class.build_value(statement, type)
          end
          values
        end

        [getter, setter]
      end

      def single_accessors(name, predicate, type)
        setter = lambda do |arg|
          old = @repo.query(:subject => @uri, :predicate => predicate)
          @repo.delete(*old.to_a) unless old.empty?
          arg = self.class.build_rdf_value(arg, type)
          @repo.insert(RDF::Statement.new(@uri, predicate, arg))
        end

        getter = lambda do
          statement = @repo.query(:subject => @uri, :predicate => predicate).first
          self.class.build_value(statement, type)
        end

        [getter, setter]
      end

    end
  end
end
