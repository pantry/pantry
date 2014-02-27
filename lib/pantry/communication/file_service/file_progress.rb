module Pantry
  module Communication
    class FileService

      # Informational object for keeping track of file upload progress and
      # important information.
      class UploadInfo

        # Identity of the Receiver we're sending a file to
        attr_accessor :receiver_uuid

        # The file session identity from the Receiver
        attr_accessor :file_uuid

        def initialize
          @finish_future = Celluloid::Future.new
        end

        # Block and wait for the file upload to finish
        def wait_for_finish(timeout = nil)
          @finish_future.value(timeout)
        end

        def finished!
          @finish_future.signal(OpenStruct.new(:value => self))
        end

      end

      # Sending-side version of UploadInfo
      class SendingFile < UploadInfo
        attr_reader :path, :file

        def initialize(file_path, receiver_uuid, file_uuid)
          super()
          @path = file_path
          @file_uuid = file_uuid
          @file = File.open(@path, "r")

          @receiver_uuid = receiver_uuid

          @file_size = @file.size
          @total_bytes_sent = 0

          Pantry.ui.progress_start(@file_size)
        end

        def read(offset, bytes_to_read)
          @total_bytes_sent += bytes_to_read
          Pantry.ui.progress_step(bytes_to_read)

          @file.seek(offset)
          @file.read(bytes_to_read)
        end

        def finished!
          Pantry.ui.progress_finish

          @file.close
          super
        end

        def finished?
          @total_bytes_sent == @file_size || @file.closed?
        end

      end

      # Receiving-side version of UploadInfo
      # Can be configured with a completion block that will be executed once the
      # file has been fully received and checksum verified.
      class ReceivingFile < UploadInfo

        # Location of the tempfile containing the contents of the uploaded file
        attr_reader :uploaded_path

        attr_reader :file_size, :checksum, :uploaded_path
        attr_accessor :sender_uuid

        def initialize(file_size, checksum, chunk_size, pipeline_size)
          super()
          @file_uuid = SecureRandom.uuid
          @file_size = file_size
          @checksum  = checksum

          @chunk_size    = chunk_size
          @pipeline_size = pipeline_size

          @uploaded_file = Tempfile.new(file_uuid)
          @uploaded_path = @uploaded_file.path

          @next_requested_file_offset = 0
          @current_pipeline_size      = 0

          @chunk_count      = (@file_size.to_f / @chunk_size.to_f).ceil
          @requested_chunks = 0
          @received_chunks  = 0
        end

        def on_complete(&block)
          @completion_block = block
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

        def finished!
          @uploaded_file.close

          if @completion_block && valid?
            begin
              @completion_block.call
            rescue => ex
              Pantry.logger.debug("[Receive File] Error running completion block #{ex.inspect}")
            end
          end

          super
        end

        def complete?
          @uploaded_file.closed?
        end
        alias finished? complete?

        def valid?
          return @is_valid if defined?(@is_valid)
          uploaded_checksum = Digest::SHA256.file(@uploaded_file.path).hexdigest
          @is_valid = (uploaded_checksum == @checksum)
        end

        def remove
          @uploaded_file.unlink
        end

      end

    end
  end
end
