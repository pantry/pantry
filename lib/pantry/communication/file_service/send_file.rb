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

      def send_file(file_path, receiver_uuid)
        FileService::SendingFile.new(file_path, receiver_uuid).tap do |info|
          @sending[receiver_uuid] = info
          start_transfer(receiver_uuid)
        end
      end

      def receive_message(message)
        case message.body[0]
        when "FETCH"
          Pantry.logger.debug("[Send File] (#{@file_path}) FETCH requested #{message.inspect}")
          fetch_and_return_chunk(message)
        when "FINISH"
          Pantry.logger.debug("[Send File] (#{@file_path}) FINISHED")
          clean_up(message)
        when "ERROR"
          Pantry.logger.debug("[Send File] (#{@file_path}) ERROR #{message.inspect}")
        end
      end

      protected

      def start_transfer(uuid)
        send_message(uuid, "START")
      end

      def fetch_and_return_chunk(message)
        current_file = @sending[message.from]
        return unless current_file

        chunk_offset = message.body[1].to_i
        chunk_size   = message.body[2].to_i

        chunk = current_file.read(chunk_offset, chunk_size)

        send_message(message.from, ["CHUNK", chunk],
                     chunk_offset: chunk_offset, chunk_size: chunk_size)
      end

      def clean_up(message)
        current_file = @sending[message.from]
        return unless current_file

        current_file.finished!
        @sending.delete(message.from)
      end

      def send_message(receiver_uuid, body, metadata = {})
        message    = Pantry::Message.new
        message.to = receiver_uuid

        [body].flatten.each {|part| message << part }

        metadata.each do |key, value|
          message[key] = value
        end

        @service.send_message(message)
      end

    end

  end
end
