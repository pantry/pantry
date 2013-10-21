require 'pantry/communication/server'
require 'pantry/communication/message'
require 'pantry/communication/message_filter'

module Pantry

  # The Pantry Server
  class Server

    # Initialize the Pantry Server
    def initialize(network_stack_class = Communication::Server)
      @networking = network_stack_class.new(self)
    end

    # Start up the networking stack and start the server
    def run
      @networking.run
    end

    # Close down networking and clean up resources
    def shutdown
      @networking.shutdown
    end

    # Broadcast a message to all clients, optionally filtering for certain clients.
    def publish_message(message, filter = Communication::MessageFilter.new)
      @networking.publish_message(message,filter)
    end

    # Send a request to the Client(s) with the given identity.
    # Returns a Future object, use #value to get the response from the Client
    # when it's available.
    def send_request(client_identity, message)
      @networking.send_request(
        message, Communication::MessageFilter.new(:identity => client_identity))
    end

    # Handle unsolicited messages received from the networking layer
    def receive_message(message)
      # Process our own messages
    end

  end
end
