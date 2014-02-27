module Pantry
  module Communication

    # Chunk file sending tool that implements the protocol as described here
    #  http://zguide.zeromq.org/page:all#Transferring-Files
    #
    # As this actor receives chunk requests from the Receiver, it reads that chunk
    # from the given file and sends it along.
    class FileService::SendFile
      include Celluloid

      def initialize(service)
        @service = service
        @sending = {}
      end

      def send_file(file_path, receiver_uuid, file_uuid)
        sender_info = FileService::SendingFile.new(file_path, receiver_uuid, file_uuid)

        @sending[file_uuid] = sender_info
        send_message(sender_info, "START")

        sender_info
      end

      def receive_message(from_identity, message)
        current_file_info = @sending[message.to]
        return unless current_file_info

        case message.body[0]
        when "FETCH"
          Pantry.logger.debug("[Send File] FETCH requested #{message.inspect}")
          fetch_and_return_chunk(current_file_info, message)
        when "FINISH"
          Pantry.logger.debug("[Send File] FINISHED cleaning up for #{message.inspect}")
          clean_up(current_file_info, message)
        when "ERROR"
          Pantry.logger.debug("[Send File] ERROR #{message.inspect}")
        end
      end

      protected

      def fetch_and_return_chunk(current_file, message)
        chunk_offset = message.body[1].to_i
        chunk_size   = message.body[2].to_i

        chunk = current_file.read(chunk_offset, chunk_size)

        send_message(current_file, ["CHUNK", chunk], chunk_offset: chunk_offset, chunk_size: chunk_size)
      end

      def clean_up(current_file, message)
        current_file.finished!
        @sending.delete(message.to)
      end

      def send_message(sender_info, body, metadata = {})
        message    = Pantry::Message.new
        message.to = sender_info.file_uuid

        [body].flatten.each {|part| message << part }

        metadata.each do |key, value|
          message[key] = value
        end

        @service.send_message(sender_info.receiver_uuid, message)
      end

    end

  end
end
