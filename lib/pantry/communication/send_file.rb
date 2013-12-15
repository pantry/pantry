module Pantry
  module Communication

    # Chunk file sending tool that implements the protocol as described here
    #  http://zguide.zeromq.org/page:all#Transferring-Files
    #
    # As this actor receives chunk requests from the Receiver, it reads that chunk
    # from the given file and sends it along.
    class SendFile
      include Celluloid

      def initialize(networking, file_path, receiver_uuid)
        @networking    = networking
        @file_path     = file_path
        @receiver_uuid = receiver_uuid

        @file = File.open(@file_path, "r")

        send_message("START")
      end

      def uuid
        @receiver_uuid
      end

      def finished?
        @file.closed?
      end

      def receive_message(message)
        case message.body[0]
        when "FETCH"
          Pantry.logger.debug("[Send File] (#{@file_path}) FETCH requested #{message.inspect}")
          fetch_and_return_chunk(message)
        when "FINISH"
          Pantry.logger.debug("[Send File] (#{@file_path}) FINISHED")
          clean_up_and_shut_down
        when "ERROR"
          Pantry.logger.debug("[Send File] (#{@file_path}) ERROR #{message.inspect}")
          notify_error(message)
        end
      end

      protected

      def send_message(body, metadata = {})
        message = Pantry::Message.new
        message.uuid = @receiver_uuid

        [body].flatten.each {|part| message << part }

        metadata.each do |key, value|
          message[key] = value
        end

        @networking.send_message(message)
      end

      def fetch_and_return_chunk(message)
        chunk_offset = message.body[1].to_i
        chunk_size   = message.body[2].to_i

        @file.seek(chunk_offset)
        chunk = @file.read(chunk_size)

        send_message(["CHUNK", chunk], chunk_offset: chunk_offset, chunk_size: chunk_size)
      end

      def clean_up_and_shut_down
        @file.close
      end

      def notify_error(message)
        # Do something here
        clean_up_and_shut_down
      end
    end

  end
end
