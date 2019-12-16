module Spira
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator
      # Unfortunately, we have to tie Uniqueness validators to a class.
      # Note: the `setup` hook has been deprecated in rails 4.1 and completely
      # removed in rails 4.2; the klass is now found in #{options[:class]}.
      if ActiveModel::VERSION::MAJOR <= 3 ||
         (ActiveModel::VERSION::MAJOR == 4 && ActiveModel::VERSION::MINOR < 1)
        def setup(klass)
          @klass = klass
        end
      else
        def initialize(options)
          super
          @klass = options.fetch(:class)
        end
      end

      def validate_each(record, attribute, value)
        @klass.find_each(conditions: {attribute => value}) do |other_record|
          if other_record.subject != record.subject
            record.errors.add(attribute, "is already taken")
            break
          end
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
