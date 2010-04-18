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
      # @private
      def build_value(statement, type, existing_relation = nil)
        case
          when statement == nil
            nil
          when type.is_a?(Class) && type.ancestors.include?(Spira::Type)
            type.unserialize(statement.object)
          when type.is_a?(Symbol)
            klass = begin 
              Kernel.const_get(type.to_s)
            rescue NameError
              unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Resource)
                raise TypeError, "#{type} is not a Spira Resource (referenced as #{type} by #{self}"
              end
            end
            case
              when false && existing_relation && (existing_relation.uri == statement.object.to_uri)
                existing_relation
              else
                promise { klass.find(statement.object) || 
                          klass.create(statement.object) }
            end
          else
            raise TypeError, "Unable to unserialize #{statement.object} for #{type}"
        end
      end

      # @private
      def build_rdf_value(value, type)
        case
          when type.is_a?(Class) && type.ancestors.include?(Spira::Type)
            type.serialize(value)
          when value && value.class.ancestors.include?(Spira::Resource)
            value.uri
          when type == RDF::URI && value.is_a?(RDF::URI)
            value
          else
            raise TypeError, "Unable to serialize #{value} for #{type}"
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
        type = case
            when opts[:type].nil?
              Spira::Types::Any
            when opts[:type].is_a?(Symbol)
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
