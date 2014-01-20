module Pantry
  module Communication

    class FileService
      include Celluloid::ZMQ
      finalizer :shutdown

      attr_reader :identity

      def initialize(server_host, port, security)
        @host = server_host
        @port = port

        @socket = Celluloid::ZMQ::RouterSocket.new
        @socket.identity = @identity = SecureRandom.uuid
        @socket.linger = 0

        @security = security
        @security.configure_socket(@socket)

        @receiver = FileService::ReceiveFile.new_link(self)
        @sender   = FileService::SendFile.new_link(self)
      end

      def secure_with(security_handler)
        @security = security_handler
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
        @receiver.receive_file(size, checksum).tap do |info|
          info.receiver_identity = @socket.identity
        end
      end

      # Inform the service that we want to start sending a file up to the receiver
      # who's listening on the given UUID.
      def send_file(file_path, receiver_identity, file_uuid)
        Pantry.logger.debug("[FileService] Sending file #{file_path} to #{receiver_identity}")
        @sender.send_file(file_path, receiver_identity, file_uuid)
      end

      def send_message(identity, message)
        @socket.write(
          [
            identity,
            SerializeMessage.to_zeromq(message)
          ].flatten
        )
      end

      def receive_message(from_identity, message)
        @sender.async.receive_message(from_identity, message)
        @receiver.async.receive_message(from_identity, message)
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

        from_identity = @socket.read

        while @socket.more_parts?
          next_message << @socket.read
        end

        async.receive_message(
          from_identity, SerializeMessage.from_zeromq(next_message)
        )
      end

    end

  end
end
