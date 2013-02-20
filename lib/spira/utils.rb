module Spira
  module Utils
    ##
    # Rename a resource in the repository to the new given subject.
    # Changes are immediately saved to the repository.
    #
    # @param [RDF::Resource] old_subject
    # @param [RDF::Resource] new_subject
    # @param [RDF::Repository] repository
    def rename!(old_subject, new_subject, repository = nil)
      repository ||= Spira.repository(:default)
      update_repository = RDF::Repository.new

      old_subject_statements = repository.query(:subject => old_subject)
      old_subject_statements.each do |statement|
        update_repository << RDF::Statement.new(new_subject, statement.predicate, statement.object)
      end

      old_object_statements = repository.query(:object => old_subject)
      old_object_statements.each do |statement|
        update_repository << RDF::Statement.new(statement.subject, statement.predicate, new_subject)
      end

      repository.insert *update_repository
      repository.delete *(old_subject_statements + old_object_statements)
    end
    module_function :rename!
  end
end
