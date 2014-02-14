module Pantry
  module Communication

    # The SendSocket allows one-way asynchronous communication to the server.
    # This is implemented through the ZMQ DEALER socket, which communicates with
    # the Server's ROUTER socket.
    class SendSocket < WritingSocket

      def build_socket
        Celluloid::ZMQ::DealerSocket.new
      end

      def open_socket(socket)
        socket.connect("tcp://#{host}:#{port}")
      end

    end
  end
end
