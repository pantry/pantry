module Pantry
  module Communication

    # The SubscribeSocket manages the Subscription side of the Pub/Sub channel,
    # using a 0MQ PUB socket. This socket can subscribe to any number of streams
    # depending on the filtering given. Messages received by this socket are passed
    # to the configured listener as Messages.
    class SubscribeSocket < ReadingSocket

      def initialize(host, port)
        super
        @filter = ClientFilter.new
      end

      def filter_on(client_filter)
        @filter = client_filter
      end

      def build_socket
        socket = Celluloid::ZMQ::SubSocket.new
        socket.linger = 0

        socket.connect("tcp://#{host}:#{port}")

        @filter.streams.each do |stream|
          socket.subscribe(stream)
        end

        socket
      end

    end
  end
end
