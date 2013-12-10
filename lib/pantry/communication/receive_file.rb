module Pantry
  module Communication

    # Chunk file receiving tool that implements the protocol as described here
    #  http://zguide.zeromq.org/page:all#Transferring-Files
    #
    # In short, this tool requests chunks in a pipeline flow, writing out
    # the received chunks to the file system at the given path.
    class ReceiveFile
      include Celluloid

      # The UUID of the communication stream that will be used throughout
      # the file transfer process
      attr_reader :uuid

      PIPELINE_SIZE = 10
      CHUNK_SIZE    = 250_000

      def initialize(networking, save_path, file_size, file_checksum)
        @uuid          = SecureRandom.uuid

        @networking    = networking
        @save_path     = save_path
        @file_size     = file_size
        @file_checksum = file_checksum

        @next_requested_file_offset = 0

      end

      def receive_message(message)
        if message.body[0] == "START"
          Pantry.logger.debug("[Receive File] (#{@save_path}) Received START message #{message.inspect}")
          @client_identity = message.from
          fill_the_pipeline
        end
      end

      def finished?

      end

      protected

      def fill_the_pipeline
        PIPELINE_SIZE.times do
          fetch_next_chunk
        end
      end

      def fetch_next_chunk
        message = Pantry::Message.new
        message.uuid = @uuid
        message.to   = @client_identity

        message << "FETCH"
        message << @next_requested_file_offset
        message << CHUNK_SIZE

        @next_requested_file_offset += CHUNK_SIZE

        Pantry.logger.debug("[Receive File] (#{@save_path}) Requesting #{message.inspect}")

        @networking.publish_message(message)
      end

    end

  end
end
