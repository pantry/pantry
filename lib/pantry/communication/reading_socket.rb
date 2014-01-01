module Pantry
  module Communication

    # Base class of all sockets that read messages from ZMQ.
    # Not meant for direct use, please use one of the subclasses for specific
    # functionality.
    class ReadingSocket
      include Celluloid::ZMQ
      finalizer :shutdown

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

      def shutdown
        @running = false
      end

      # Some ZMQ socket types include the source as the first packet of a message.
      # We need to know if the socket in question does this so we can properly
      # build the Message coming in.
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
        next_message = []

        # Drop the ZMQ given source packet, it's extraneous for our purposes
        if has_source_header?
          @socket.read
        end

        next_message << @socket.read

        while @socket.more_parts?
          next_message << @socket.read
        end

        async.handle_message(
          SerializeMessage.from_zeromq(next_message)
        )
      end

      def handle_message(message)
        @listener.handle_message(message) if @listener
      end

    end

  end
end
