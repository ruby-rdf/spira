module Spira
  module Serialization
    ##
    # Support for Psych (YAML) custom serializer.
    #
    # This causes the subject and all attributes to be saved to a YAML or JSON serialization
    # in such a way that they can be restored in the future.
    #
    # @param [Psych::Coder] coder
    def encode_with(coder)
      coder["subject"] = subject
      attributes.each {|p,v| coder[p.to_s] = v if v}
    end

    ##
    # Support for Psych (YAML) custom de-serializer.
    #
    # Updates a previously allocated Spira::Base instance to that of a previously
    # serialized instance.
    #
    # @param [Psych::Coder] coder
    def init_with(coder)
      instance_variable_set(:"@subject", coder["subject"])
      assign_attributes coder.map.except("subject")
    end
  end
end
