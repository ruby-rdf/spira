module Spira
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator
      # Unfortunately, we have to tie Uniqueness validators to a class.
      def setup(klass)
        @klass = klass
      end

      def validate_each(record, attribute, value)
        predicate = @klass.properties[attribute][:predicate]
        q = RDF::Query.new(:subject => {predicate => value})
        unless @klass.repository.query(q).empty?
          record.errors.add(attribute, "is already taken")
        end
      end
    end

    module ClassMethods
      # Validates whether the value of the specified attributes are unique across the system.
      # Useful for making sure that only one user
      # can be named "davidhh".
      #
      #   class Person < Spira::Base
      #     validates_uniqueness_of :user_name
      #   end
      #
      def validates_uniqueness_of(*attr_names)
        validates_with UniquenessValidator, _merge_attributes(attr_names)
      end
    end
  end
end
