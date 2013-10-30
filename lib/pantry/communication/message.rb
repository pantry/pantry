module Pantry
  module Communication

    # Message is the container for communication between the client and server.
    # Messages know what stream they've been sent down, have a type to differentiate them
    # from each other, and an arbitrarily large body.
    #
    # Every message has three sections, the stream, metadata, and body. The stream defines
    # where the message needs to go. The metadata defines information about the message, it's
    # type, if it needs a response, everything that doesn't go in the body. The body is the
    # request message itself.
    class Message

      # Where or who is this message intended for (Can be an identity or a stream)
      attr_accessor :to

      # Who is this message coming from (Should be an identity)
      attr_accessor :from

      # What type of message are we?
      attr_accessor :type

      # The full body of the message. See specific message types for handling.
      attr_accessor :body

      attr_writer :requires_response

      def initialize(message_type = nil)
        @type = message_type
        @body = []

        @requires_response = false
        @forwarded         = false
      end

      # Set the source of this message either by an object that responds to #identity
      # or a string.
      def from=(source)
        if source.respond_to?(:identity)
          @from = source.identity
        else
          @from = source
        end
      end

      # Flag this message as requiring a response
      def requires_response!
        @requires_response = true
      end

      # Does this message require a response message?
      def requires_response?
        @requires_response
      end

      # Has this message been forwarded through the Server?
      # This flag is checked when the message comes back through the Server,
      # which lets it know if the message needs to continue back to another Client.
      def forwarded!
        @forwarded = true
      end

      def forwarded?
        @forwarded
      end

      # Build a copy of this message to use when responding
      # to the message
      def build_response
        response = self.clone
        response.body = []
        response.to   = self.from
        response.from = self.to
        response.requires_response = false
        response
      end

      # Add a message part to this Message's body
      def <<(part)
        @body << part
        @body.flatten!
      end

      # Get a copy of the body data usable for sending down the network.
      # For now, this ensures that every entry is a string.
      def body
        @body.map(&:to_s)
      end

      # Return all of this message's metadata as a hash
      def metadata
        {
          :type              => self.type,
          :from              => self.from,
          :to                => self.to,
          :requires_response => self.requires_response?,
          :forwarded         => self.forwarded?
        }
      end

      # Given a hash, pull out the parts into local variables
      def metadata=(hash)
        @type              = hash[:type]
        @from              = hash[:from]
        @to                = hash[:to]
        @requires_response = hash[:requires_response]
        @forwarded         = hash[:forwarded]
      end

    end

  end
end
