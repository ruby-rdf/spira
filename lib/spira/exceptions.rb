module Spira

  ##
  # For cases when a method is called which requires a `type` method be
  # declared on a Spira class.
  class NoTypeError < StandardError ; end

  ##
  # For cases when a projection fails a validation check
  class ValidationError < StandardError; end
end
