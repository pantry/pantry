
module Pantry
  module Communication

    # Message is the container for communication between the client and server.
    # Messages know what stream they've been sent down, have a type to differentiate them
    # from each other, and an arbitrarily large body.
    class Message

      # When receiving a message from pub/sub, which stream this Message originated from.
      attr_accessor :stream

      # What type of message are we?
      attr_accessor :type

      # The full body of the message. See specific message types for handling.
      attr_accessor :body

      # Identity of who sent this message
      attr_accessor :identity

      attr_writer :requires_response

      def initialize(message_type = nil)
        @type              = message_type
        @requires_response = false

        @body = []
      end

      # Flag this message as requiring a response
      def requires_response!
        @requires_response = true
      end

      # Does this message require a response message?
      def requires_response?
        @requires_response
      end

      # Build a copy of this message to use when responding
      # to the message
      def build_response
        response = self.clone
        response.body = []
        response.requires_response = false
        response
      end

      # Add a message part to this Message's body
      def <<(part)
        @body << part
      end

    end

  end
end
