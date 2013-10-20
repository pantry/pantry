require 'pantry/config'
require 'pantry/communication/message'
require 'pantry/communication/message_filter'
require 'pantry/communication/publish_socket'
require 'pantry/communication/receive_socket'
require 'pantry/communication/wait_list'

module Pantry

  # The Pantry Server
  class Server

    def initialize
      @response_wait_list = Communication::WaitList.new
    end

    # Start up the networking stack and start the server
    def run
      @publish_socket = Communication::PublishSocket.new(
        Pantry.config.server_host,
        Pantry.config.pub_sub_port
      )
      @publish_socket.open

      @receive_socket = Communication::ReceiveSocket.new(
        Pantry.config.server_host,
        Pantry.config.receive_port
      )
      @receive_socket.add_listener(self)
      @receive_socket.open
    end

    # Broadcast a message to all clients, optionally filtering for certain clients.
    def publish_to_clients(message, filter = Communication::MessageFilter.new)
      @publish_socket.send_message(message, filter)
    end

    # Send a message to the Client(s) with the given identity.
    # Returns a Future object, use #value to get the response from the Client
    # when it's available.
    def request_from_client(client_identity, message)
      publish_to_clients(
        message, Communication::MessageFilter.new(:identity => client_identity)
      )

      @response_wait_list.wait_for(client_identity, message)
    end

    def handle_message(message)
      puts "Server got message #{message}"
      if @response_wait_list.waiting_for?(message)
        @response_wait_list.received(message)
      else
        # Process our own messages
      end
    end

    # Close down the networking and clean up resources
    def shutdown
      @publish_socket.close
      @receive_socket.close
    end

  end
end
