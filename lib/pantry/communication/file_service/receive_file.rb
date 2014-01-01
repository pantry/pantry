module Pantry
  module Communication

    # Chunk file receiving tool that implements the protocol as described here
    #  http://zguide.zeromq.org/page:all#Transferring-Files
    #
    # In short, this tool requests chunks in a pipeline flow, writing out
    # the received chunks to the file system at the given path.
    class FileService::ReceiveFile
      include Celluloid

      attr_accessor :pipeline_size, :chunk_size

      def initialize(service, chunk_size: 250_000, pipeline_size: 10)
        @service = service

        @chunk_size    = chunk_size
        @pipeline_size = pipeline_size

        @receiving = {}
      end

      def receive_file(file_size, checksum)
        FileService::ReceivingFile.new(
          file_size, checksum, chunk_size, pipeline_size
        ).tap do |info|
          @receiving[info.uuid] = info
        end
      end

      def receive_message(message)
        case message.body[0]
        when "START"
          Pantry.logger.debug("[Receive File] Received START message #{message.inspect}")
          fill_the_pipeline(message)
        when "CHUNK"
          Pantry.logger.debug("[Receive File] Received CHUNK message #{message.metadata}")
          process_chunk(message)
        else
          Pantry.logger.error("[Recieve File] Received message with unknown body")
        end
      end

      protected

      def fill_the_pipeline(message)
        current_file = @receiving[message.to]
        return unless current_file

        current_file.chunks_to_fetch do |offset, size|
          Pantry.logger.debug("[Receive File] Fetching #{offset} x #{size} for #{current_file.uuid}")
          send_message(current_file.uuid, "FETCH", offset, size)
        end
      end

      def process_chunk(message)
        current_file = @receiving[message.to]
        return unless current_file

        chunk_offset = message[:chunk_offset]
        chunk_size   = message[:chunk_size]
        chunk_data   = message.body[1]

        current_file.write_chunk(chunk_offset, chunk_size, chunk_data)

        if current_file.complete?
          finalize_file(current_file)
        else
          fill_the_pipeline(message)
        end
      end

      def finalize_file(current_file)
        if current_file.valid?
          send_message(current_file.uuid, "FINISH")
        else
          current_file.remove
          send_message(current_file.uuid, "ERROR", "Checksum did not match the uploaded file")
        end

        current_file.finished!
        @receiving.delete(current_file.uuid)
      end

      def send_message(uuid, *body)
        message    = Pantry::Message.new
        message.to = uuid

        body.each {|part| message << part }

        @service.send_message(message)
      end

    end

  end
end
