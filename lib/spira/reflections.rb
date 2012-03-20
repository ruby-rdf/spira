require "spira/association_reflection"

module Spira
  module Reflections
    # Returns a hash containing all AssociationReflection objects for the current class
    # Example:
    #
    #   Invoice.reflections
    #   Account.reflections
    #
    def reflections
      read_inheritable_attribute(:reflections) || write_inheritable_attribute(:reflections, {})
    end

    def reflect_on_association(association)
      reflections[association].is_a?(AssociationReflection) ? reflections[association] : nil
    end
  end
end
