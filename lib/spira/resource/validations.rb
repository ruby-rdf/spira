module Spira
  module Resource

    ##
    # Instance methods relating to validations for a Spira resource.  This
    # includes the default assertions.
    #
    # @see Spira::Resource::InstanceMethods
    # @see Spira::Resource::ClassMethods
    # @see Spira::Resource::DSL
    module Validations

      ##
      # The {Spira::Errors} object for this instance.
      #
      # @return [Spira::Errors] The errors
      # @see Spira::Errors
      def errors
        @errors ||= []
      end

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
end
