require 'pantry/communication'
require 'pantry/communication/message_filter'

module Pantry
  module Communication

    # The PublishSocket handles the Publish side of Pub/Sub using
    # a 0MQ PUB socket. Messages can be published to all listening clients
    # or can be filtered to certain clients using a MessageFilter.
    # See SubscribeSocket for the receiving end.
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

      def send_message(message, filter)
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
