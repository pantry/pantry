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

      def receive_message(from_identity, message)
        if current_file = @receiving[message.to]
          current_file.sender_identity = from_identity
        else
          return
        end

        case message.body[0]
        when "START"
          Pantry.logger.debug("[Receive File] Received START message #{message.inspect}")
          fill_the_pipeline(current_file, message)
        when "CHUNK"
          Pantry.logger.debug("[Receive File] Received CHUNK message #{message.metadata}")
          process_chunk(current_file, message)
        end
      end

      protected

      def fill_the_pipeline(current_file, message)
        current_file.chunks_to_fetch do |offset, size|
          Pantry.logger.debug("[Receive File] Fetching #{offset} x #{size} for #{current_file.uuid}")
          send_message(current_file, "FETCH", offset, size)
        end
      end

      def process_chunk(current_file, message)
        chunk_offset = message[:chunk_offset]
        chunk_size   = message[:chunk_size]
        chunk_data   = message.body[1]

        current_file.write_chunk(chunk_offset, chunk_size, chunk_data)

        if current_file.complete?
          finalize_file(current_file)
        else
          fill_the_pipeline(current_file, message)
        end
      end

      def finalize_file(current_file)
        if current_file.valid?
          Pantry.logger.debug("[Receive File] File #{current_file.uuid} finished")
          send_message(current_file, "FINISH")
        else
          Pantry.logger.debug("[Receive File] File #{current_file.uuid} did not upload successfully")
          current_file.remove
          send_message(current_file, "ERROR", "Checksum did not match the uploaded file")
        end

        current_file.finished!
        @receiving.delete(current_file.uuid)
      end

      def send_message(current_file, *body)
        message    = Pantry::Message.new
        message.to = current_file.uuid

        body.each {|part| message << part }

        @service.send_message(current_file.sender_identity, message)
      end

    end

  end
end
