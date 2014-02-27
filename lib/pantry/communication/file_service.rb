module Pantry
  module Communication

    # FileService manages the sending and receiving of files that are too big
    # to cleanly send as a plain ZeroMQ message.
    # Every Client and Server has its own FileService handler which can manage
    # both sending and receiving files from each other.
    #
    # Setting up a file transfer processes backwards from what may be expected.
    # As the Receiver actually requests chunks from the Sender, a protocol that's
    # heavily influenced by http://zguide.zeromq.org/page:all#Transferring-Files,
    # a Receiver must be initiated first on the receiving end, which will then pass
    # back the appropriate information (receiver_uuid and file upload UUID) a
    # Sender needs to start up and run.
    #
    # From this the two parts complete the process automatically. A Receiver writes the
    # data it receives in a tempfile, and must be configured with a completion block
    # to move the uploaded file to its final location.
    #
    # To ensure this object has as little special-casing code as possible, the communication
    # takes place in a ZeroMQ ROUTER <-> ROUTER topology.
    class FileService
      include Celluloid::ZMQ
      finalizer :shutdown

      attr_reader :identity

      def initialize(server_host, port, security)
        @host = server_host
        @port = port

        @socket = Celluloid::ZMQ::RouterSocket.new
        @socket.set(::ZMQ::ROUTER_MANDATORY, 1)
        @socket.identity = @identity = SecureRandom.uuid
        Communication.configure_socket(@socket)

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
      # size and checksum. Returns a UploadInfo struct with the information for
      # the Sender.
      def receive_file(size, checksum)
        Pantry.logger.debug("[FileService] Receiving file of size #{size} and checksum #{checksum}")
        @receiver.receive_file(size, checksum).tap do |info|
          info.receiver_uuid = @socket.identity
        end
      end

      # Inform the service that we want to start sending a file up to the receiver
      # who's listening on the given UUID.
      def send_file(file_path, receiver_uuid, file_uuid)
        Pantry.logger.debug("[FileService] Sending file #{file_path} to #{receiver_uuid}")
        @sender.send_file(file_path, receiver_uuid, file_uuid)
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
