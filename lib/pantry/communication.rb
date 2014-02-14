module Pantry

  # The Communication subsystem of Pantry is managed via 0MQ through the
  # Celluloid::ZMQ library.
  module Communication
    Celluloid::ZMQ.init

    # Configure a ZMQ socket with some common options
    def self.configure_socket(socket)
      # Ensure the socket doesn't spam us trying to reconnect
      # after a disconnect or authentication failure
      socket.set(::ZMQ::RECONNECT_IVL,     1_000)
      socket.set(::ZMQ::RECONNECT_IVL_MAX, 30_000)

      # Drop all messages on shutdown
      socket.linger = 0
    end
  end

end
