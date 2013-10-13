require 'ffi-rzmq'

module Pantry
  module Communication

    def self.build_socket(socket_type)
      current_context.socket(socket_type)
    end

    def self.current_context
      @@zmq_context ||= ZMQ::Context.new
    end

  end
end
