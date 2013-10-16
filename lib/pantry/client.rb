require 'pantry/communication/subscribe_socket'

module Pantry
  # The pantry Client
  class Client

    attr_reader :server_host, :subscribe_port

    def initialize(server_host: '127.0.0.1', subscribe_port: 10101)
      @server_host    = server_host
      @subscribe_port = subscribe_port

      @subscribe_socket = Communication::SubscribeSocket.new(self, server_host, subscribe_port)
      @message_subscriptions = {}
    end

    def on(message, &block)
      @message_subscriptions[message.to_s] = block
    end

    # Callback from SubscribeSocket when a message is received
    def handle_message(message)
      if callback = @message_subscriptions[message]
        callback.call
      end
    end

    def shutdown
      @subscribe_socket.shutdown
    end
  end
end
