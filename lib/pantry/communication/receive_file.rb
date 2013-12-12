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
        @current_pipeline_size      = 0

        @chunk_count      = (file_size.to_f / CHUNK_SIZE.to_f).ceil
        @requested_chunks = 0
        @received_chunks  = 0
      end

      def receive_message(message)
        if message.body[0] == "START"
          Pantry.logger.debug("[Receive File] (#{@save_path}) Received START message #{message.inspect}")
          @client_identity = message.from
          fill_the_pipeline
        elsif message.body[0] == "CHUNK"
          Pantry.logger.debug("[Receive File] (#{@save_path}) Received CHUNK message #{message.metadata}")
          process_chunk(message)
        else
          Pantry.logger.error("[Recieve File] (#{@save_path}) Received message with unknown body")
        end
      end

      def finished?
        @received_chunks == @chunk_count
      end

      protected

      def fill_the_pipeline
        chunks_to_fill_pipeline = [
          (PIPELINE_SIZE - @current_pipeline_size),
          @chunk_count - @requested_chunks
        ].min

        chunks_to_fill_pipeline.times do
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
        @current_pipeline_size += 1
        @requested_chunks      += 1

        Pantry.logger.debug("[Receive File] (#{@save_path}) Requesting #{message.inspect}")

        @networking.publish_message(message)
      end

      def process_chunk(message)
        chunk_offset = message[:chunk_offset]
        chunk_size   = message[:chunk_size]

        @current_pipeline_size -= 1
        @received_chunks       += 1

        fill_the_pipeline
      end

    end

  end
end
