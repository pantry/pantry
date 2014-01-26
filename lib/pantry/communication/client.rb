module Pantry
  module Communication

    class Client
      include Celluloid

      def initialize(listener)
        @listener = listener
        @response_wait_list = Communication::WaitList.new
      end

      def run
        @security = Communication::Security.new_client

        @subscribe_socket = Communication::SubscribeSocket.new_link(
          Pantry.config.server_host,
          Pantry.config.pub_sub_port,
          @security
        )
        @subscribe_socket.add_listener(self)
        @subscribe_socket.filter_on(@listener.filter)
        @subscribe_socket.open

        @send_socket = Communication::SendSocket.new_link(
          Pantry.config.server_host,
          Pantry.config.receive_port,
          @security
        )
        @send_socket.open

        @file_service = Communication::FileService.new_link(
          Pantry.config.server_host,
          Pantry.config.file_service_port,
          @security
        )
        @file_service.start_client
      end

      # Receive a message from the server
      def handle_message(message)
        if @response_wait_list.waiting_for?(message)
          @response_wait_list.received(message)
        else
          @listener.receive_message(message)
        end
      end

      def send_request(message)
        @response_wait_list.wait_for(message).tap do
          send_message(message)
        end
      end

      def send_message(message)
        message.from = @listener
        @send_socket.send_message(message)
      end

      def receive_file(file_size, file_checksum)
        @file_service.receive_file(file_size, file_checksum)
      end

      def send_file(file_path, receiver_identity, file_uuid)
        @file_service.send_file(file_path, receiver_identity, file_uuid)
      end

    end

  end
end
