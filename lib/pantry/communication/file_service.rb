module Pantry
  module Communication

    class FileService
      include Celluloid::ZMQ
      finalizer :shutdown

      def initialize(server_host, port)
        @host = server_host
        @port = port

        @socket = Celluloid::ZMQ::DealerSocket.new
        @socket.linger = 0

        @receiver = FileService::ReceiveFile.new_link(@socket)
        @sender   = FileService::SendFile.new_link(@socket)
      end

      def start_server
        @socket.bind("tcp://#{@host}:#{@port}")
        run
      end

      def start_client
        @socket.connect("tcp://#{@host}:#{@port}")
        run
      end

      def shutdown
        @running = false
      end

      def run
        @running = true
        self.async.process_messages
      end

      # Inform the service that it will soon be receiving a file of the given
      # size and checksum. Returns a FileInfo struct with the information for
      # the Sender.
      def receive_file(size, checksum)
        Pantry.logger.debug("[FileService] Receiving file of size #{size} and checksum #{checksum}")
        @receiver.receive_file(size, checksum)
      end

      # Inform the service that we want to start sending a file up to the receiver
      # who's listening on the given UUID.
      def send_file(file_path, receiver_uuid)
        Pantry.logger.debug("[FileService] Sending file #{file_path} to #{receiver_uuid}")
        @sender.send_file(file_path, receiver_uuid)
      end

      def send_message(message)
        @socket.write(
          SerializeMessage.to_zeromq(message)
        )
      end

      def receive_message(message)
        @sender.receive_message(message)
        @receiver.receive_message(message)
      end

      protected

      def process_messages
        while @running
          process_next_message
        end

        @socket.close
      end

      def process_next_message
        next_message = []

        next_message << @socket.read

        while @socket.more_parts?
          next_message << @socket.read
        end

        Pantry.logger.debug("[File Service] Got message #{next_message.inspect}")

        async.receive_message(
          SerializeMessage.from_zeromq(next_message)
        )
      end

    end

  end
end
