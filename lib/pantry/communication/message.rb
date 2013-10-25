require 'pantry/communication/client_filter'

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

      # When receiving a message from pub/sub, which stream this Message originated from.
      attr_accessor :stream

      # What type of message are we?
      attr_accessor :type

      # The full body of the message. See specific message types for handling.
      attr_accessor :body

      # Identity of who sent this message
      attr_accessor :source

      # ClientFilter that limit who should receive this message
      attr_accessor :filter

      attr_writer :requires_response

      def initialize(message_type = nil)
        @type              = message_type
        @requires_response = false

        @body   = []
        @filter = Pantry::Communication::ClientFilter.new
      end

      # Set the source of this message either by an object that responds to #identity
      # or a string.
      def source=(source)
        if source.respond_to?(:identity)
          @source = source.identity
        else
          @source = source
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
          :source            => self.source,
          :requires_response => self.requires_response?,
          :filter            => self.filter.to_hash
        }
      end

      # Given a hash, pull out the parts into local variables
      def metadata=(hash)
        @type              = hash[:type]
        @source            = hash[:source]
        @requires_response = hash[:requires_response]
        @filter            = Pantry::Communication::ClientFilter.new(hash[:filter] || {})
      end

    end

  end
end
