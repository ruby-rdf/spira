module Spira
 module Resource

   # This module contains all user-exposed methods for use in building a model class.
   # It is used to extend classes that include Spira::Resource.
   # @see a little bit of magic in Spira::Resource#included as well--some
   # tricks need class_eval before this module is included.
   #
    module DSL  

      def default_source(name)
        @repository_name = name
        @repository = Spira.repository(name)
      end
  
      def default_base_uri(string)
        @base_uri = string
      end
      
      def default_vocabulary(string)
        @default_vocabulary = uri
      end

      def property(name, opts = {} )
        predicate = case
          when opts[:predicate]
            opts[:predicate]
          when @default_vocabulary.nil?
            raise(ArgumentError, "A :predicate option is required for types without a default vocabulary")
          else @default_vocabulary
            RDF::URI.new(@default_vocabulary.to_s + "/" + name.to_s)
        end

        type = opts[:type] || String
        @properties[name] = predicate
        name_equals = (name.to_s + "=").to_sym
        self.class_eval do
  
          define_method(name_equals) do |arg|
            old = @repo.query(:subject => @uri, :predicate => predicate)
            @repo.delete(*old.to_a) unless old.empty?
            arg = arg.uri if arg.class.ancestors.include?(Spira::Resource)
            @repo.insert(RDF::Statement.new(@uri, predicate, arg))
          end
  
          define_method(name) do
            statement = @repo.query(:subject => @uri, :predicate => predicate).first
            value = case
              when statement.nil?
                nil
              when type == String
                statement.object.object.to_s
              when type == Integer
                statement.object.object
              when type.is_a?(Symbol)
                klass = Kernel.const_get(type.to_s.capitalize)
                raise TypeError, "#{klass} is not a Spira Resource (referenced as #{type} by #{self}" unless klass.ancestors.include? Spira::Resource
                klass.find statement.object
            end
          end
  
        end
      end

      def has_many(name, opts = {})
        predicate = case
          when opts[:predicate]
            opts[:predicate]
          when @default_vocabulary.nil?
            raise(ArgumentError, "A :predicate option is required for types without a default vocabulary")
          else @default_vocabulary
            RDF::URI.new(@default_vocabulary.to_s + "/" + name.to_s)
        end

        type = opts[:type] || String
        @properties[name] = predicate
        name_equals = (name.to_s + "=").to_sym
        self.class_eval do

          define_method(name_equals) do |arg|
            old = @repo.query(:subject => @uri, :predicate => predicate)
            @repo.delete(*old.to_a) unless old.empty?
            new = []
            arg.each do |value|
              value = value.uri if value.class.ancestors.include?(Spira::Resource)
              new << RDF::Statement.new(@uri, predicate, value)
            end
            @repo.insert(*new)
          end

          define_method(name) do
            values = []
            statements = @repo.query(:subject => @uri, :predicate => predicate)
            statements.each do |statement|
              value = case
                when type == String
                  statement.object.object.to_s
                when type == Integer
                  statement.object.object
                when type.is_a?(Symbol)
                  klass = Kernel.const_get(type.to_s.capitalize)
                  raise TypeError, "#{klass} is not a Spira Resource (referenced as #{type} by #{self}" unless klass.ancestors.include? Spira::Resource
                  klass.find(statement.object) || klass.create(statement.object)
              end
              values << value
            end
            values
          end
        end
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

      include Spira::Resource::ClassMethods

    end
  end
end
