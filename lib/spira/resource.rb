require "active_support/core_ext/class"

module Spira
  module Resource
    def type(uri = nil)
      if uri
        if @type
          raise ResourceDeclarationError, "Attempt to redeclare the type for the resource"
        else
          if uri.is_a?(RDF::URI)
            singleton_class.class_eval do
              define_method(:_type) { uri }
              private :_type
            end
            @type = uri
          else
            raise TypeError, "Type must be a RDF::URI"
          end
        end
      else
        respond_to?(:_type, true) ? _type : nil
      end
    end
  end
end
