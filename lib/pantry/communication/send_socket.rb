require 'pantry/communication'
require 'pantry/communication/message_filter'

module Pantry
  module Communication

    # The SendSocket allows one-way asynchronous communication to the server.
    # This is implemented through the ZMQ DEALER socket, which communicates with
    # the Server's ROUTER socket.
    class SendSocket
      include Celluloid::ZMQ

      attr_reader :port, :host

      def initialize(host, port)
        @host = host
        @port = port
      end

      def open
        @socket = Celluloid::ZMQ::DealerSocket.new
        @socket.linger = 0
        @socket.connect("tcp://#{@host}:#{@port}")
      end

      def send_message(message, filter = MessageFilter.new)
        @socket.write(serialize(message, filter))
      end

      def close
        @socket.close if @socket
      end

      private

      def serialize(message, filter)
        [
          filter.stream,
          message.type,
          message.body
        ].flatten.compact
      end
    end
  end
end
