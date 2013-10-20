require 'celluloid/zmq'
require 'pantry/communication'
require 'pantry/communication/message_filter'

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

      def send_message(message, filter = MessageFilter.new)
        @socket.write(serialize(message, filter))
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
