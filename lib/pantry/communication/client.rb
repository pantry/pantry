require 'pantry/config'
require 'pantry/communication'
require 'pantry/communication/subscribe_socket'
require 'pantry/communication/send_socket'

module Pantry
  module Communication

    class Client

      def initialize(listener)
        @listener = listener
      end

      def run
        @subscribe_socket = Communication::SubscribeSocket.new(
          Pantry.config.server_host,
          Pantry.config.pub_sub_port
        )
        @subscribe_socket.add_listener(self)
        @subscribe_socket.filter_on(
          Communication::MessageFilter.new(
            application: @listener.application,
            environment: @listener.environment,
            roles: @listener.roles,
            identity: @listener.identity
          )
        )
        @subscribe_socket.open

        @send_socket = Communication::SendSocket.new(
          Pantry.config.server_host,
          Pantry.config.receive_port
        )
        @send_socket.open
      end

      def shutdown
        @subscribe_socket.close
        @send_socket.close
      end

      def handle_message(message)
        @listener.receive_message(message)
      end

    end

  end
end
