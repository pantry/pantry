require 'pantry/communication'
require 'pantry/communication/writing_socket'

module Pantry
  module Communication

    # The SendSocket allows one-way asynchronous communication to the server.
    # This is implemented through the ZMQ DEALER socket, which communicates with
    # the Server's ROUTER socket.
    class SendSocket < WritingSocket

      def build_socket
        socket = Celluloid::ZMQ::DealerSocket.new
        socket.linger = 0
        socket.connect("tcp://#{host}:#{port}")
        socket
      end

    end
  end
end
