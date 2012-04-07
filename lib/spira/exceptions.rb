module Spira

  class SpiraError < StandardError ; end

  ##
  # For cases when a method is called which requires a `type` method be
  # declared on a Spira class.
  class NoTypeError < SpiraError ; end

  ##
  # For cases in which a repository is required but none has been given
  class NoRepositoryError < SpiraError ; end

  ##
  # For errors in the DSL, such as invalid predicates
  class ResourceDeclarationError < SpiraError ; end

  ##
  # Raised when user tries to assign a non-existing property
  class PropertyMissingError < SpiraError ; end
end
