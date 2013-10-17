require 'pantry/communication'
require 'pantry/communication/message_filter'

module Pantry
  module Communication
    class PublishSocket
      include Celluloid::ZMQ

      attr_reader :port, :host

      def initialize(host, port)
        @host = host
        @port = port
      end

      def open
        @socket = Celluloid::ZMQ::PubSocket.new
        @socket.linger = 0
        @socket.bind("tcp://#{@host}:#{@port}")
      end

      def send_message(message, filter = nil)
        @socket.write(serialize(message, filter || MessageFilter.new))
      end

      def close
        @socket.close
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
