require 'pantry/communication/publish_socket'

module Pantry
  # The Pantry Server
  class Server

    attr_reader :publish_port

    def initialize(host: "127.0.0.1", publish_port: 10101)
      @publish_port   = publish_port
      @publish_socket = Communication::PublishSocket.new(host, publish_port)
    end

    def publish_to_clients(message)
      @publish_socket.send_message(message)
    end

  end
end
