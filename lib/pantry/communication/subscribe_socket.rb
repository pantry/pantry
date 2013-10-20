require 'pantry/communication'
require 'pantry/communication/message'
require 'pantry/communication/message_filter'

module Pantry
  module Communication

    # The SubscribeSocket manages the Subscription side of the Pub/Sub channel,
    # using a 0MQ PUB socket. This socket can subscribe to any number of streams
    # depending on the filtering given. Messages received by this socket are passed
    # to the configured listener as Messages.
    class SubscribeSocket
      include Celluloid::ZMQ

      def initialize(server_host, subscribe_port)
        @server_host    = server_host
        @subscribe_port = subscribe_port
        @listener = nil
        @filter = MessageFilter.new
      end

      def add_listener(listener)
        @listener = listener
      end

      def filter_on(message_filter)
        @filter = message_filter
      end

      def open
        @socket = Celluloid::ZMQ::SubSocket.new
        @socket.linger = 0

        @socket.connect("tcp://#{@server_host}:#{@subscribe_port}")

        @filter.streams.each do |stream|
          @socket.subscribe(stream)
        end

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
