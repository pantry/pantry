module Pantry

  # The Communication subsystem of Pantry is managed via 0MQ through the
  # Celluloid::ZMQ library.
  module Communication
    Celluloid::ZMQ.init
  end

end
