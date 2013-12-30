module Pantry
  module Communication

    # Chunk file sending tool that implements the protocol as described here
    #  http://zguide.zeromq.org/page:all#Transferring-Files
    #
    # As this actor receives chunk requests from the Receiver, it reads that chunk
    # from the given file and sends it along.
    class SendFile
      include Celluloid

      attr_reader :uuid

      def initialize(networking, file_path, receiver_uuid: nil, listener: nil)
        @networking    = networking
        @file_path     = file_path
        @uuid          = receiver_uuid || SecureRandom.uuid
        @listener      = listener      || Pantry::ProgressListener.new

        start_file_transfer(receiver_uuid)
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

      def start_file_transfer(known_receiver)
        @file = File.open(@file_path, "r")
        @total_bytes_sent = 0

        @listener.start_progress(@file.size)
        send_message("START") if known_receiver
      end

      def fetch_and_return_chunk(message)
        chunk_offset = message.body[1].to_i
        chunk_size   = message.body[2].to_i

        @file.seek(chunk_offset)
        chunk = @file.read(chunk_size)

        send_message(["CHUNK", chunk], chunk_offset: chunk_offset, chunk_size: chunk_size)
        notify_progress(chunk_size)
      end

      def send_message(body, metadata = {})
        message = Pantry::Message.new
        message.uuid = @uuid

        [body].flatten.each {|part| message << part }

        metadata.each do |key, value|
          message[key] = value
        end

        @networking.send_message(message)
      end

      def notify_error(message)
        @listener.error(message.body[1])
        clean_up_and_shut_down
      end

      def notify_progress(bytes_sent)
        @total_bytes_sent += bytes_sent
        @listener.step_progress(@total_bytes_sent)
      end

      def clean_up_and_shut_down
        @file.close
        @listener.finished
      end

    end

  end
end
