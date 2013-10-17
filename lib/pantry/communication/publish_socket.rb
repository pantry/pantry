require 'pantry/communication'

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

      def send_message(message)
        @socket.write(serialize(message))
      end

      def close
        @socket.close
      end

      private

      def serialize(message)
        [
          message.type,
          message.body
        ].flatten.compact
      end
    end
  end
end
