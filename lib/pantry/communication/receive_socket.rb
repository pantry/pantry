require 'celluloid/zmq'
require 'pantry/communication'
require 'pantry/communication/reading_socket'

module Pantry
  module Communication

    # The ReceiveSocket receives communication from Clients via the
    # Dealer / Router socket pair. This class is the Server's Router side.
    class ReceiveSocket < ReadingSocket

      def build_socket
        socket = Celluloid::ZMQ::RouterSocket.new
        socket.bind("tcp://#{host}:#{port}")
        socket
      end

      def has_source_header?
        true
      end

    end

  end
end
