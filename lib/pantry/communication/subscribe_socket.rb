require 'pantry/communication'

module Pantry
  module Communication
    class SubscribeSocket
      include Celluloid::ZMQ

      def initialize(server_host, subscribe_port)
        @server_host    = server_host
        @subscribe_port = subscribe_port
        @listener = nil
      end

      def add_listener(listener)
        @listener = listener
      end

      def open
        @socket = SubSocket.new
        @socket.linger = 0

        @socket.connect("tcp://#{@server_host}:#{@subscribe_port}")
        @socket.subscribe("")

        @running = true
        self.async.run
      end

      def close
        @running = false
      end

      def run
        while @running
          async.handle_message(@socket.read)
        end
      end

      def handle_message(message)
        @listener.handle_message(message) if @listener
      end
    end
  end
end
