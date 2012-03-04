module Spira

  ##
  # Spira::Errors represents a collection of validation errors for a Spira
  # resource.  It tracks a list of errors for each field.
  #
  # This class does not perform validations.  It only tracks the results of
  # them.
  class Errors

    ##
    # Creates a new Spira::Errors
    #
    # @return [Spira::Errors]
    def initialize
      @errors = {}
    end

    ##
    # Returns true if there are no errors, false otherwise
    #
    # @return [true, false]
    def empty?
      @errors.all? do |field, errors| errors.empty? end
    end

    ##
    # Returns true if there are errors, false otherwise
    #
    # @return [true, false]
    def any?
      !empty?
    end

    ##
    # Returns true if the given property or list has any errors
    #
    # @param [Symbol] name The name of the property or list
    # @return [true, false]
    def any_for?(property)
      !self.for(property).empty?
    end
 
    ##
    # Add an error to a given property or list
    #
    # @example Add an error to a property
    #     errors.add(:username, "cannot be nil")
    # @param [Symbol] property The property or list to add the error to
    # @param [String] problem The error
    # @return [Void]
    def add(property, problem)
      @errors[property] ||= []
      @errors[property].push problem
    end

    ##
    # The list of errors for a given property or list
    #
    # @example Get the errors for the `:username` field
    #     errors.add(:username, "cannot be nil")
    #     errors.for(:username) #=> ["cannot be nil"]
    # @param [Symbol] property The property or list to check
    # @return [Array<String>] The list of errors
    def for(property)
      @errors[property] || []
    end
    alias_method :[], :for

    ##
    # Clear all errors
    # 
    # @return [Void]
    def clear
      @errors = {}
    end

    ##
    # Return all errors as strings
    #
    # @example Get all errors
    #     errors.add(:username, "cannot be nil")
    #     errors.each #=> ["username cannot be nil"]
    # @return [Array<String>]
    def each
      @errors.map do |property, problems|
        problems.map do |problem|
          property.to_s + " " + problem  
        end
      end.flatten
    end


  end
end
