require 'pantry/config'
require 'pantry/communication/publish_socket'

module Pantry
  # The Pantry Server
  class Server

    def start
      @publish_socket = Communication::PublishSocket.new(
        Pantry.config.server_host,
        Pantry.config.pub_sub_port
      )
      @publish_socket.open
    end

    def publish_to_clients(message)
      @publish_socket.send_message(message)
    end

    def close
      @publish_socket.close
    end

  end
end
