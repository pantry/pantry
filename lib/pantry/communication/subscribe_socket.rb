require 'pantry/communication'

module Pantry
  module Communication
    class SubscribeSocket
      include Celluloid::ZMQ

      attr_reader :host, :port

      def initialize(client, server_host, server_port)
        @client = client
        @port = server_port
        @host = server_host

        @socket = SubSocket.new
        @socket.linger = 0

        @socket.connect("tcp://#{@host}:#{@port}")
        @socket.subscribe("")

        @running = true

        self.async.run
      end

      def shutdown
        @running = false
      end

      def run
        while @running
          async.handle_message(@socket.read)
        end
      end

      def handle_message(message)
        @client.handle_message(message)
      end
    end
  end
end
