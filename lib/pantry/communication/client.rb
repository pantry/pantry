module Pantry
  module Communication

    class Client
      include Celluloid

      def initialize(listener)
        @listener = listener
        @response_wait_list = Communication::WaitList.new
      end

      def run
        @subscribe_socket = Communication::SubscribeSocket.new_link(
          Pantry.config.server_host,
          Pantry.config.pub_sub_port
        )
        @subscribe_socket.add_listener(self)
        @subscribe_socket.filter_on(@listener.filter)
        @subscribe_socket.open

        @send_socket = Communication::SendSocket.new_link(
          Pantry.config.server_host,
          Pantry.config.receive_port
        )
        @send_socket.open
      end

      # Receive a message from the server
      def handle_message(message)
        if @response_wait_list.waiting_for?(message)
          @response_wait_list.received(message)
        else
          @listener.receive_message(message)
        end
      end

      # Send a request to the server, setting up a future
      # that will eventually have the response
      def send_request(message)
        @response_wait_list.wait_for(message).tap do
          send_message(message)
        end
      end

      # Send a message back up to the server
      def send_message(message)
        message.from = @listener
        @send_socket.send_message(message)
      end

      # Send a file up to the Server.
      def send_file(file_path, receiver_uuid, options = {})
        uploader = Pantry::Communication::SendFile.new_link(self, file_path, receiver_uuid, **options)
        @response_wait_list.wait_for_persistent(uploader)
        uploader.uuid
      end

    end

  end
end
