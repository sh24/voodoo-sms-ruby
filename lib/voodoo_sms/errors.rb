# frozen_string_literal

# TODO: Make this into a module
class VoodooSMS
  module Error
    class BadRequest < StandardError; end
    class Unauthorised < StandardError; end
    class NotEnoughCredit < StandardError; end
    class Forbidden < StandardError; end
    class MessageTooLarge < StandardError; end
    class Unexpected < StandardError; end
    class RequiredParameter < StandardError; end
    class InvalidParameterFormat < StandardError; end
  end
end
