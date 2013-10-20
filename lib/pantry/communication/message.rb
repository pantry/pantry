
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
      attr_reader :body

      # Identity of who sent this message
      attr_accessor :identity

      def initialize(message_type = nil)
        @type = message_type
        @body = []
      end

      # Add a message part to this Message's body
      def <<(part)
        @body << part
      end

    end

  end
end
