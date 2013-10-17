require 'pantry/communication'
require 'pantry/communication/message'

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
        @socket = Celluloid::ZMQ::SubSocket.new
        @socket.linger = 0

        @socket.connect("tcp://#{@server_host}:#{@subscribe_port}")
        @socket.subscribe("")

        @running = true
        self.async.process_messages
      end

      def close
        @running = false
      end

      protected

      def process_messages
        while @running
          process_next_message
        end
      end

      def process_next_message
        message = Message.new(@socket.read)

        while @socket.more_parts?
          message << @socket.read
        end

        async.handle_message(message)
      end

      def handle_message(message)
        @listener.handle_message(message) if @listener
      end

    end
  end
end
