module Pantry
  module Communication

    # Base class of all sockets that write messages through ZMQ.
    # Not meant for direct use, please use one of the subclasses for specific
    # functionality.
    class WritingSocket
      include Celluloid::ZMQ

      attr_reader :host, :port

      def initialize(host, port, security)
        @host     = host
        @port     = port
        @security = security
      end

      def open
        @socket = build_socket
        @security.configure_socket(@socket)

        open_socket(@socket)
      end

      def build_socket
        raise "Implement the socket setup."
      end

      def open_socket(socket)
        raise "Connect / Bind the socket built in #build_socket"
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
