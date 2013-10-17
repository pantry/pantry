require 'pantry/config'
require 'pantry/communication/message'
require 'pantry/communication/publish_socket'

module Pantry
  # The Pantry Server
  class Server

    def run
      @publish_socket = Communication::PublishSocket.new(
        Pantry.config.server_host,
        Pantry.config.pub_sub_port
      )
      @publish_socket.open
    end

    def publish_to_clients(message, filter = nil)
      @publish_socket.send_message(message, filter)
    end

    def shutdown
      @publish_socket.close
    end

  end
end
