require 'pantry/config'
require 'pantry/communication'
require 'pantry/communication/subscribe_socket'
require 'pantry/communication/send_socket'
require 'pantry/communication/wait_list'

module Pantry
  module Communication

    class Client

      # TODO HACK For now this always comes from the server
      # so we work around not knowing the server's identity right now.
      # Should update this to store the server's identity on auth
      TEMP_SERVER_IDENTITY = "server"

      def initialize(listener)
        @listener = listener
        @response_wait_list = Communication::WaitList.new
      end

      def run
        @subscribe_socket = Communication::SubscribeSocket.new(
          Pantry.config.server_host,
          Pantry.config.pub_sub_port
        )
        @subscribe_socket.add_listener(self)
        @subscribe_socket.filter_on(@listener.filter)
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

      # Receive a message from the server
      def handle_message(message)
        message.source = TEMP_SERVER_IDENTITY

        if @response_wait_list.waiting_for?(message)
          @response_wait_list.received(message)
        else
          @listener.receive_message(message)
        end
      end

      # Send a message back up to the server
      def send_message(message)
        @send_socket.send_message(message)
      end

      # Send a request to the server, setting up a future
      # that will eventually have the response
      def send_request(message)
        @send_socket.send_message(message)
        @response_wait_list.wait_for(TEMP_SERVER_IDENTITY, message)
      end

    end

  end
end
