require 'socket'

require 'pantry/communication/server'
require 'pantry/communication/message'
require 'pantry/communication/message_filter'
require 'pantry/commands/server_commands'

module Pantry

  # The Pantry Server
  class Server

    # This server's Identity. By default this is the server's hostname but can be specified manually.
    attr_accessor :identity

    # Initialize the Pantry Server
    def initialize(network_stack_class = Communication::Server)
      @commands   = Commands::ServerCommands.new
      @networking = network_stack_class.new(self)
      @identity   = current_hostname
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

    # Map a message event type to a handler Proc.
    # All messages have a type, use this method to register a block to
    # handle any messages that come to this Server of the given type.
    def on(message_type, &block)
      @commands.add_handler(message_type, &block)
    end

    # Callback from the network when a message is received from a client.
    def receive_message(message)
      results = @commands.process(message)
      if message.requires_response?
        send_results_back_to_requester(message, results)
      end
    end

    # Send a request to the Client(s) with the given identity.
    # Returns a Future object, use #value to get the response from the Client
    # when it's available.
    def send_request(client_identity, message)
      message.requires_response!
      message.source = self

      @networking.send_request(
        message, Communication::MessageFilter.new(:identity => client_identity))
    end

    protected

    def current_hostname
      Socket.gethostname
    end

    def send_results_back_to_requester(message, results)
      response_message = message.build_response
      response_message.source = self
      response_message << results

      @networking.publish_message(response_message,
                                  Communication::MessageFilter.new(:identity => message.source))
    end

  end
end
