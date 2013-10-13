require 'ffi-rzmq'
require 'pantry/communication'

module Pantry
  module Communication
    class SubscribeSocket

      attr_reader :host, :port

      def initialize(server_host, server_port)
        @port = server_port
        @host = server_host

        @socket = Communication.build_socket(ZMQ::SUB)
        @socket.connect("tcp://#{@host}:#{@port}")
        @socket.setsockopt(ZMQ::SUBSCRIBE, '')
      end

      def messages
        [get_one_message]
      end

      def get_one_message
        message_body = ''
        error_or_bytes = @socket.recv_string(message_body)

        if error_or_bytes < 0
          ZMQ::LibZMQ.zmq_strerror(error_or_bytes).read_string
        end

        message_body
      end
    end
  end
end
