module Spira

  ##
  # For cases when a method is called which requires a `type` method be
  # declared on a Spira class.
  class NoTypeError < StandardError ; end

  ##
  # For cases when a projection fails a validation check
  class ValidationError < StandardError ; end

  ##
  # For cases in which a repository is required but none has been given
  class NoRepositoryError < StandardError ; end

  ##
  # For errors in the DSL, such as invalid predicates
  class ResourceDeclarationError < StandardError ; end

  ##
  # Raised when user tries to assign a non-existing property
  class PropertyMissingError < StandardError ; end
end
