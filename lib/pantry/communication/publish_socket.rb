module Pantry
  module Communication

    # The PublishSocket handles the Publish side of Pub/Sub using
    # a 0MQ PUB socket. Messages can be published to all listening clients
    # or can be filtered to certain clients using a ClientFilter.
    # See SubscribeSocket for the receiving end.
    class PublishSocket < WritingSocket

      def build_socket
        socket = Celluloid::ZMQ::PubSocket.new
        socket.linger = 0
        socket.bind("tcp://#{host}:#{port}")
        socket
      end

    end
  end
end
