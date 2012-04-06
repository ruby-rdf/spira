require "active_support/core_ext/module/aliasing"

module Spira
  ##
  # Instance methods relating to validations for a Spira resource.  This
  # includes the default assertions.
  module Validations
    def self.included(base)
      base.class_eval do
        ##
        # The validation errors collection associated with this instance.
        #
        # @return [Spira::Errors]
        # @see Spira::Errors
        attr_reader :errors

        ##
        # The list of validation functions for this projection
        #
        # @return [Array<Symbol>]
        def self.validators
          @validators ||= []
        end

        alias_method_chain :save, :validation

        define_model_callbacks :validation
      end
    end

    ##
    # Run any model validations and populate the errors object accordingly.
    # Returns true if the model is valid, false otherwise
    #
    # @return [True, False]
    def validate
      unless self.class.send(:validators).empty?
        errors.clear
        self.class.send(:validators).each do | validator | self.send(validator) end
      end
      errors.empty?
    end

    ##
    # Run validations on this model and raise a Spira::ValidationError if the validations fail.
    #
    # @see #validate
    # @return true
    def validate!
      validate || raise(ValidationError, "Failed to validate #{self.inspect}: " + errors.each.join(';'))
    end

    def save_with_validation(*args)
      if run_callbacks(:validation) { validate }
        save_without_validation(*args)
      else
        nil
      end
    end

    def save!(*args)
      save(*args) || raise(ValidationError, "Could not save #{self.inspect} due to validation errors: " + errors.each.join(';'))
    end


    private

    ##
    # Assert a fact about this instance.  If the given expression is false,
    # an error will be noted.
    #
    # @example Assert that a title is correct
    #     assert(title == 'xyz', :title, 'bad title')
    # @param  [Any] boolean The expression to evaluate
    # @param  [Symbol] property The property or has_many to mark as incorrect on failure
    # @param  [String] message The message to record if this assertion fails
    # @return [Void]
    def assert(boolean, property, message)
      errors.add(property, message) unless boolean
    end

    ##
    # A default helper assertion.  Asserts that a given property is set.
    #
    # @param  [Symbol] name The property to check
    # @return [Void]
    def assert_set(name)
      assert(!(self.send(name).nil?), name, "#{name.to_s} cannot be nil")
    end

    ##
    # A default helper assertion.  Asserts that a given property is numeric.
    #
    # @param  [Symbol] name The property to check
    # @return [Void]
    def assert_numeric(name)
      assert(self.send(name).is_a?(Numeric), name, "#{name.to_s} must be numeric (was #{self.send(name)})")
    end
  end
end
