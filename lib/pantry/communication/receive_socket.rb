require 'celluloid/zmq'
require 'pantry/communication'
require 'pantry/communication/message'

module Pantry
  module Communication

    class ReceiveSocket
      include Celluloid::ZMQ

      def initialize(host, port)
        @host     = host
        @port     = port
        @listener = nil
      end

      def add_listener(listener)
        @listener = listener
      end

      def open
        @socket = Celluloid::ZMQ::RouterSocket.new
        @socket.bind("tcp://#{@host}:#{@port}")

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

        @socket.close
      end

      def process_next_message
        message = Message.new

        message.stream = @socket.read
        message.type = @socket.read

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
