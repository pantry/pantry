require 'celluloid/zmq'
require 'json'

require 'pantry/communication'
require 'pantry/communication/message'

module Pantry
  module Communication

    # Base class of all sockets that read messages from ZMQ.
    # Not meant for direct use, please use one of the subclasses for specific
    # functionality.
    class ReadingSocket
      include Celluloid::ZMQ

      attr_reader :host, :port

      def initialize(host, port)
        @host     = host
        @port     = port
        @listener = nil
      end

      def add_listener(listener)
        @listener = listener
      end

      def open
        @socket = build_socket
        @running = true
        self.async.process_messages
      end

      def build_socket
        raise "Implement the socket setup. Must return the socket object already connected/bound."
      end

      def close
        @running = false
      end

      def has_source_header?
        false
      end

      protected

      def process_messages
        while @running
          process_next_message
        end

        @socket.close
      end

      def process_next_message
        message = Message.new

        if has_source_header?
          message.source = @socket.read
        end

        message.stream = @socket.read
        message.metadata = JSON.parse(@socket.read, symbolize_names: true)

        while @socket.more_parts?
          message << @socket.read
        end

        async.handle_message(message)
      end

      def handle_message(message)
        @listener.handle_message(message) if @listener
      end

    end

  end
end
