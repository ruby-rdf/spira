module Spira
  module Utils
    ##
    # Rename the subject of a Spira object to something else
    # @param [RDF::Resource] new_subject
    # @param [RDF::Repository] repository
    # @return [Spira::Base] A new instance using this subject
    def rename!(new_subject, repository = nil)
      repository ||= Spira.repository
      repository.rename!(subject, new_subject)
      self.class.for(new_subject)
    end
  end
end

module RDF
  class Repository
    ##
    # Rename a resource in the Repository to the new given subject.
    #
    # @param [RDF::Resource] old_subject
    # @param [RDF::Resource] new_subject
    # @return [self]
    def rename!(old_subject, new_subject)
      transaction(mutable: true) do |tx|
        query(subject: old_subject) do |statement|
          tx.insert RDF::Statement.new(new_subject, statement.predicate, statement.object)
          tx.delete(statement)
        end
        query(object: old_subject) do |statement|
          tx.insert RDF::Statement.new(statement.subject, statement.predicate, new_subject)
          tx.delete(statement)
        end
      end
    end
  end
end
