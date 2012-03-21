module RDF
  class URI
    ##
    # Create a projection of this URI as the given Spira::Resource class.
    # Equivalent to `klass.for(self, *args)`
    #
    # @example Instantiating a URI as a Spira Resource
    #     RDF::URI('http://example.org/person/bob').as(Person)
    # @param [Class] klass
    # @param [*Any] args Any arguments to pass to klass.for
    # @yield [self] Executes a given block and calls `#save!`
    # @yieldparam [self] self The newly created instance
    # @return [Klass] An instance of klass
    def as(klass, *args, &block)
      raise ArgumentError, "#{klass} is not a Spira resource" unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Base)
      klass.for(self, *args, &block)
    end
  end

  class Node
    ##
    # Create a projection of this Node as the given Spira::Resource class.
    # Equivalent to `klass.for(self, *args)`
    #
    # @example Instantiating a blank node as a Spira Resource
    #     RDF::Node.new.as(Person)
    # @param [Class] klass
    # @param [*Any] args Any arguments to pass to klass.for
    # @yield [self] Executes a given block and calls `#save!`
    # @yieldparam [self] self The newly created instance
    # @return [Klass] An instance of klass
    def as(klass, *args)
      raise ArgumentError, "#{klass} is not a Spira resource" unless klass.is_a?(Class) && klass.ancestors.include?(Spira::Base)
      klass.for(self, *args)
    end
  end
end
