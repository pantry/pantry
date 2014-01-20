module Pantry
  module Communication

    # The ReceiveSocket receives communication from Clients via the
    # Dealer / Router socket pair. This class is the Server's Router side.
    class ReceiveSocket < ReadingSocket

      def build_socket
        Celluloid::ZMQ::RouterSocket.new
      end

      def open_socket(socket)
        socket.bind("tcp://#{host}:#{port}")
      end

      def has_source_header?
        true
      end

    end

  end
end
