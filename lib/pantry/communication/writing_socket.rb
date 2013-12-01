module Pantry
  module Communication

    # Base class of all sockets that write messages through ZMQ.
    # Not meant for direct use, please use one of the subclasses for specific
    # functionality.
    class WritingSocket
      include Celluloid::ZMQ

      attr_reader :host, :port

      def initialize(host, port)
        @host     = host
        @port     = port
      end

      def open
        @socket = build_socket
      end

      def build_socket
        raise "Implement the socket setup. Must return the socket object already connected/bound."
      end

      def close
        @socket.close if @socket
      end

      def send_message(message)
        @socket.write(
          SerializeMessage.to_zeromq(message)
        )
      end

    end
  end
end
