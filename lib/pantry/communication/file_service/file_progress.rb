module Pantry
  module Communication
    class FileService

      class FileProgressInfo

        def initialize
          @finish_future = Celluloid::Future.new
        end

        def wait_for_finish(timeout = nil)
          @finish_future.value(timeout)
        end

        def finished!
          @finish_future.signal(OpenStruct.new(:value => self))
        end

      end

      # Informational object to keep track of the progress of sending a file
      # up to a receiver.
      class SendingFile < FileProgressInfo
        attr_reader :path, :receiver_identity, :uuid, :file

        def initialize(file_path, receiver_identity, file_uuid)
          super()
          @path = file_path
          @uuid = file_uuid
          @file = File.open(@path, "r")

          @receiver_identity = receiver_identity

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

      # Informational object to keep track of the progress of receiving
      # a file from a sender.
      class ReceivingFile < FileProgressInfo
        attr_reader :uuid, :file_size, :checksum, :uploaded_path

        attr_accessor :receiver_identity, :sender_identity

        def initialize(file_size, checksum, chunk_size, pipeline_size)
          super()
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
