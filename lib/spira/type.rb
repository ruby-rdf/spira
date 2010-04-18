module Spira
  module Type

    def self.included(child)
      child.extend(ClassMethods)
      Spira.type_alias(child,child)
    end

    include RDF

    module ClassMethods
      def register_alias(any)
        Spira.type_alias(any, self)
      end

      def serialize(value)
        value
      end

      def unserialize(value)
        value
      end
    end

  end
end
