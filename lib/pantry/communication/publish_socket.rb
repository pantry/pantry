require 'ffi-rzmq'
require 'pantry/communication'

module Pantry
  module Communication
    class PublishSocket

      attr_reader :port, :host

      def initialize(host, port)
        @host = host
        @port = port

        @socket = Communication.build_socket(ZMQ::PUB)
        err = @socket.bind("tcp://#{host}:#{port}")
      end

      def send_message(message)
        @socket.send_string(message.to_s)
      end
    end
  end
end
