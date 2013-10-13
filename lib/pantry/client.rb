require 'pantry/communication/subscribe_socket'

module Pantry
  # The pantry Client
  class Client

    attr_reader :server_host, :subscribe_port

    def initialize(server_host: '127.0.0.1', subscribe_port: 10101)
      @server_host    = server_host
      @subscribe_port = subscribe_port

      @subscribe_socket = Communication::SubscribeSocket.new(server_host, subscribe_port)
    end

    def messages
      @subscribe_socket.messages
    end

  end
end
