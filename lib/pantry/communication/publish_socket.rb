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
        @socket = PubSocket.new
        @socket.linger = 0
        @socket.bind("tcp://#{@host}:#{@port}")
      end

      def send_message(message)
        @socket.send(message.to_s)
      end

      def shutdown
        @socket.close
      end
    end
  end
end
