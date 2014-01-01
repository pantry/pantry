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
        ReceivingFile.new(file_size, checksum, chunk_size, pipeline_size).tap do |info|
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

      class ReceivingFile
        attr_reader :uuid, :file_size, :checksum, :uploaded_path

        def initialize(file_size, checksum, chunk_size, pipeline_size)
          @uuid      = SecureRandom.uuid
          @file_size = file_size
          @checksum  = checksum

          @chunk_size    = chunk_size
          @pipeline_size = pipeline_size

          @uploaded_file = Tempfile.new(uuid)
          @uploaded_path = @uploaded_file.path

          @next_requested_file_offset = 0
          @current_pipeline_size      = 0

          @chunk_count      = (@file_size.to_f / @chunk_size.to_f).ceil
          @requested_chunks = 0
          @received_chunks  = 0
        end

        def chunks_to_fetch(&block)
          chunks_to_fill_pipeline = [
            (@pipeline_size - @current_pipeline_size),
            @chunk_count - @requested_chunks
          ].min

          chunks_to_fill_pipeline.times do
            block.call(@next_requested_file_offset, @chunk_size)

            @next_requested_file_offset += @chunk_size
            @current_pipeline_size += 1
            @requested_chunks      += 1
          end
        end

        def write_chunk(offset, size, data)
          @current_pipeline_size -= 1
          @received_chunks       += 1

          @uploaded_file.seek(offset)
          @uploaded_file.write(data)

          if @received_chunks == @chunk_count
            @uploaded_file.close
          end
        end

        def complete?
          @uploaded_file.closed?
        end

        def valid?
          uploaded_checksum = Digest::SHA256.file(@uploaded_file.path).hexdigest
          uploaded_checksum == @checksum
        end

        def remove
          @uploaded_file.unlink
        end

      end

      def fill_the_pipeline(message)
        current_file = @receiving[message.from]
        return unless current_file

        current_file.chunks_to_fetch do |offset, size|
          Pantry.logger.debug("[Receive File] Fetching #{offset} x #{size} for #{current_file.uuid}")
          send_message(current_file.uuid, "FETCH", offset, size)
        end
      end

      def process_chunk(message)
        current_file = @receiving[message.from]
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
