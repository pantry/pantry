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

      attr_reader :pipeline_size, :chunk_size

      def initialize(networking, save_path, file_size, file_checksum,
                     chunk_size: 250_000, pipeline_size: 10)
        @uuid          = SecureRandom.uuid

        @networking    = networking
        @save_path     = save_path
        @file_size     = file_size
        @file_checksum = file_checksum

        @chunk_size    = chunk_size
        @pipeline_size = pipeline_size

        @next_requested_file_offset = 0
        @current_pipeline_size      = 0

        @chunk_count      = (file_size.to_f / @chunk_size.to_f).ceil
        @requested_chunks = 0
        @received_chunks  = 0
      end

      def receive_message(message)
        if message.body[0] == "START"
          Pantry.logger.debug("[Receive File] (#{@save_path}) Received START message #{message.inspect}")
          prepare_file(message)
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

      def prepare_file(message)
        @client_identity = message.from
        @file = File.open(@save_path, "w+")
      end

      def fill_the_pipeline
        chunks_to_fill_pipeline = [
          (@pipeline_size - @current_pipeline_size),
          @chunk_count - @requested_chunks
        ].min

        chunks_to_fill_pipeline.times do
          fetch_next_chunk
        end
      end

      def fetch_next_chunk
        Pantry.logger.debug("[Receive File] (#{@save_path}) Requesting #{@next_requested_file_offset} x #{@chunk_size}")
        send_message("FETCH", @next_requested_file_offset, @chunk_size)

        @next_requested_file_offset += @chunk_size
        @current_pipeline_size += 1
        @requested_chunks      += 1
      end

      def process_chunk(message)
        chunk_offset = message[:chunk_offset]
        chunk_size   = message[:chunk_size]

        @current_pipeline_size -= 1
        @received_chunks       += 1

        @file.write(message.body[1])

        if finished?
          finalize_file
        else
          fill_the_pipeline
        end
      end

      def finalize_file
        @file.close
        file_checksum = Digest::SHA256.file(@file.path).hexdigest

        if file_checksum != @file_checksum
          File.unlink(@file.path)
          send_message("ERROR", "Checksum did not match the uploaded file")
        end
      end

      def send_message(*body)
        message = Pantry::Message.new
        message.uuid = @uuid
        message.to   = @client_identity

        body.each {|part| message << part }

        @networking.publish_message(message)
      end

    end

  end
end
