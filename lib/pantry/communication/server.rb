module Pantry
  module Communication

    # The communication server embodies everything the Pantry Server
    # needs to properly communicate with Clients.
    class Server
      include Celluloid

      #
      # +listener+ must respond to the #receive_message method
      def initialize(listener)
        @listener           = listener
        @response_wait_list = Communication::WaitList.new
      end

      # Start up the networking layer, opening up sockets and getting
      # ready for client communication.
      def run
        @publish_socket = Communication::PublishSocket.new_link(
          Pantry.config.server_host,
          Pantry.config.pub_sub_port
        )
        @publish_socket.open

        @receive_socket = Communication::ReceiveSocket.new_link(
          Pantry.config.server_host,
          Pantry.config.receive_port
        )
        @receive_socket.add_listener(self)
        @receive_socket.open
      end

      # Send a request to all clients, expecting a result. Returns a Future
      # which can be queried later for the client response.
      def send_request(message)
        @response_wait_list.wait_for(message).tap do
          publish_message(message)
        end
      end

      # Send a message to all connected subscribers without modifying the package.
      # Used when handling requests meant for other clients (say from the CLI). The source
      # is untouched so the Client(s) handling know how to respond.
      def forward_message(message)
        message.forwarded!
        publish_message(message)
      end

      # Send a message to all clients who match the given filter.
      def publish_message(message)
        message.from ||= @listener
        @publish_socket.send_message(message)
      end

      # Listener callback from ReceiveSocket. See if we need to match this response
      # with a previous request or if it's a new message entirely.
      def handle_message(message)
        if message.forwarded?
          forward_message(message)
        elsif @response_wait_list.waiting_for?(message)
          @response_wait_list.received(message)
        else
          @listener.receive_message(message)
        end
      end

      # Prepare to receive from a Client or CLI. Returns the UUID to be passed along
      # to the appropriate Sender for proper hookup
      def receive_file(save_path, file_size, file_checksum)
        receiver = Pantry::Communication::ReceiveFile.new_link(self, save_path, file_size, file_checksum)
        @response_wait_list.wait_for_persistent(receiver)
        receiver.uuid
      end

      # Prepare to send a file to whoever is listening. Returns the UUID to be passed
      # along to Receivers waiting to download the given file
      def send_file(file_path)
        sender = Pantry::Communication::SendFile.new_link(self, file_path)
        @response_wait_list.wait_for_persistent(sender)
        sender.uuid
      end

    end

  end
end
