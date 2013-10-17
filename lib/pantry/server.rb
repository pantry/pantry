require 'pantry/config'
require 'pantry/communication/message'
require 'pantry/communication/publish_socket'

module Pantry

  # The Pantry Server
  class Server

    # Start up the networking stack and start the server
    def run
      @publish_socket = Communication::PublishSocket.new(
        Pantry.config.server_host,
        Pantry.config.pub_sub_port
      )
      @publish_socket.open
    end

    # Broadcast a message to all clients, optionally filtering for certain
    # clients.
    def publish_to_clients(message, filter = nil)
      @publish_socket.send_message(message, filter)
    end

    # Close down the networking and clean up resources
    def shutdown
      @publish_socket.close
    end

  end
end
